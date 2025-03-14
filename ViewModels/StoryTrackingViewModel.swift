//
//  StoryTrackingViewModel.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/5/25.
//

import Foundation
import Combine
import os.log

class StoryTrackingViewModel: ObservableObject {
    @Published var trackedStories: [TrackedStory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var activeStoryId: String?

    private var pollCancellable: AnyCancellable?
    private var fetchTask: Task<Void, Never>? = nil
    private var lastFetchTime: Date? = nil
    private let fetchDebounceInterval: TimeInterval = 5.0 // 5 seconds debounce
    private let logger = Logger(subsystem: "com.newsflowai.app", category: "StoryTrackingViewModel")

    // Start polling every 3 minutes (180 seconds)
    func startPolling() {
        logger.info("Starting polling for story updates")
        // Cancel any existing polling
        stopPolling()
        
        pollCancellable = Timer.publish(every: 180, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // Create a Task to handle the async call
                Task {
                    await self?.fetchTrackedStories()
                }
            }
    }

    func stopPolling() {
        logger.info("Stopping polling for story updates")
        pollCancellable?.cancel()
        pollCancellable = nil
    }

    // Fetch all tracked stories from your backend with debouncing
    @MainActor
    func fetchTrackedStories() async {
        // Cancel any existing fetch task properly
        if let existingTask = fetchTask {
            existingTask.cancel()
            // Wait a moment for the task to actually cancel
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Check if we've fetched recently to avoid excessive API calls
        if let lastTime = lastFetchTime, Date().timeIntervalSince(lastTime) < self.fetchDebounceInterval {
            logger.info("Skipping fetch - last fetch was less than \(self.fetchDebounceInterval) seconds ago")
            return
        }
        
        // Create a new task for this fetch operation
        let newTask = Task {
            do {
                // Only set loading state if we're not already loading
                if !self.isLoading {
                    self.isLoading = true
                }
                self.errorMessage = nil
                
                logger.info("Fetching tracked stories from backend")
                
                // Check for cancellation before making the network call
                if Task.isCancelled { 
                    logger.info("Task cancelled before network call")
                    return 
                }
                
                // Use a dedicated task for the network call that can be properly cancelled
                let stories = try await withTaskCancellationHandler {
                    try await SupabaseClient.shared.fetchTrackedStories()
                } onCancel: {
                    logger.info("Network call cancelled")
                }
                
                // Update last fetch time
                self.lastFetchTime = Date()
                
                // Check for cancellation again after the network call
                if Task.isCancelled { 
                    logger.info("Task cancelled after network call")
                    return 
                }
                
                self.trackedStories = stories
                self.isLoading = false
                logger.info("Fetched \(stories.count) tracked stories")
            } catch is CancellationError {
                logger.info("Fetch operation was cancelled")
                // Don't update UI state if cancelled
            } catch {
                // Only update if the task hasn't been cancelled
                if !Task.isCancelled {
                    // Don't clear existing stories on error
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    logger.error("Error fetching tracked stories: \(error.localizedDescription)")
                }
            }
        }
        
        // Store the new task
        fetchTask = newTask
    }

    @MainActor
    func startTracking(keyword: String, sourceArticleId: String? = nil) async {
        logger.info("Starting tracking for keyword: \(keyword)")
        // Call the backend to create a tracked story.
        do {
            self.isLoading = true
            self.errorMessage = nil
            
            logger.debug("Creating tracked story in backend")
            let newStory = try await SupabaseClient.shared.createTrackedStory(keyword: keyword, sourceArticleId: sourceArticleId)
            
            self.trackedStories.append(newStory)
            self.isLoading = false
            self.activeStoryId = newStory.id
            logger.info("Created tracked story with ID: \(newStory.id)")
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            logger.error("Error creating tracked story: \(error.localizedDescription)")
        }
    }

    @MainActor
    func stopTracking(storyId: String) async {
        logger.info("Stopping tracking for story ID: \(storyId)")
        // Call the backend to delete a tracked story.
        do {
            self.isLoading = true
            self.errorMessage = nil
            
            logger.debug("Deleting tracked story from backend")
            try await SupabaseClient.shared.deleteTrackedStory(storyId: storyId)
            
            self.trackedStories.removeAll { $0.id == storyId }
            self.isLoading = false
            if self.activeStoryId == storyId {
                self.activeStoryId = nil
            }
            logger.info("Deleted tracked story with ID: \(storyId)")
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            logger.error("Error deleting tracked story: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func togglePolling(storyId: String, enable: Bool) async {
        logger.info("\(enable ? "Enabling" : "Disabling") polling for story ID: \(storyId)")
        do {
            self.isLoading = true
            self.errorMessage = nil
            
            logger.debug("Toggling polling in backend")
            let updatedStory = try await SupabaseClient.shared.toggleStoryPolling(storyId: storyId, enable: enable)
            
            if let index = self.trackedStories.firstIndex(where: { $0.id == storyId }) {
                self.trackedStories[index] = updatedStory
            }
            self.isLoading = false
            logger.info("Successfully toggled polling for story ID: \(storyId)")
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            logger.error("Error toggling polling: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func refreshStory(storyId: String) async {
        // Check if we've fetched recently to avoid excessive API calls
        if let lastTime = lastFetchTime, Date().timeIntervalSince(lastTime) < self.fetchDebounceInterval {
            logger.info("Skipping refresh - last fetch was less than \(self.fetchDebounceInterval) seconds ago")
            return
        }
        
        do {
            logger.debug("Fetching story details from backend")
            let story = try await SupabaseClient.shared.getStoryDetails(storyId: storyId)
            
            // Update last fetch time
            self.lastFetchTime = Date()
            
            if let index = self.trackedStories.firstIndex(where: { $0.id == storyId }) {
                self.trackedStories[index] = story
                logger.info("Updated story details for ID: \(storyId)")
            }
        } catch {
            logger.error("Error refreshing story: \(error.localizedDescription)")
            // Don't set errorMessage here to avoid disrupting the UI for a background refresh
        }
    }
    
    // Method to extract main keyword from an article
    func extractMainKeyword(from title: String) -> String {
        // Simple implementation - in reality you might want something more sophisticated
        let words = title.components(separatedBy: " ")
        let commonWords = ["the", "a", "an", "and", "but", "or", "for", "nor", "on", "at", "to", "from", "by"]
        
        let significantWords = words.filter { word in
            let lowercased = word.lowercased()
            return lowercased.count > 3 && !commonWords.contains(lowercased)
        }
        
        return significantWords.first ?? title.components(separatedBy: " ").first ?? "News"
    }
}
