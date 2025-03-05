//
//  StoryTrackingViewModel.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/5/25.
//

import Foundation
import Combine

class StoryTrackingViewModel: ObservableObject {
    @Published var trackedStories: [TrackedStory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var pollCancellable: AnyCancellable?

    // Start polling every 3 minutes (180 seconds)
    func startPolling() {
        pollCancellable = Timer.publish(every: 180, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchTrackedStories()
            }
    }

    func stopPolling() {
        pollCancellable?.cancel()
    }

    // Fetch all tracked stories from your backend
    func fetchTrackedStories() {
        Task {
            do {
                await MainActor.run {
                    self.isLoading = true
                    self.errorMessage = nil
                }

                let stories = try await SupabaseClient.shared.fetchTrackedStories()

                await MainActor.run {
                    self.trackedStories = stories
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    func startTracking(keyword: String, sourceArticleId: String? = nil) {
        // Call the backend to create a tracked story.
        Task {
            do {
                let newStory = try await SupabaseClient.shared.createTrackedStory(keyword: keyword, sourceArticleId: sourceArticleId)
                await MainActor.run {
                    self.trackedStories.append(newStory)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stopTracking(storyId: String) {
        // Call the backend to delete a tracked story.
        Task {
            do {
                try await SupabaseClient.shared.deleteTrackedStory(storyId: storyId)
                await MainActor.run {
                    self.trackedStories.removeAll { $0.id == storyId }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
} 
