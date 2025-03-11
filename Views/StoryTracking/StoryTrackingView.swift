//
//  StoryTrackingView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/5/25.
//
import SwiftUI

struct StoryTrackingView: View {
    @EnvironmentObject var storyTrackingViewModel: StoryTrackingViewModel
    let keyword: String
    @State private var isPollingEnabled = false
    @State private var showAlert = false

    var body: some View {
        VStack {
            HStack {
                Text("Tracking: \(keyword)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                Button(action: {
                    showAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
                .alert("Stop Tracking", isPresented: $showAlert) {
                    Button("Stop Tracking", role: .destructive) {
                        if let story = storyTrackingViewModel.trackedStories.first(where: { $0.keyword == keyword }) {
                            // Wrap the async call in a Task
                            Task {
                                await storyTrackingViewModel.stopTracking(storyId: story.id)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to stop tracking '\(keyword)'?")
                }
            }
            .padding()

            if storyTrackingViewModel.isLoading {
                ProgressView()
                    .padding()
            } else if let story = storyTrackingViewModel.trackedStories.first(where: { $0.keyword == keyword }) {
                VStack {
                    // Toggle for auto-update
                    Toggle(isOn: $isPollingEnabled) {
                        Text("Auto-update")
                            .font(.headline)
                    }
                    .padding()
                    .onChange(of: isPollingEnabled) { _, newValue in
                        // Wrap the async call in a Task
                        Task {
                            await storyTrackingViewModel.togglePolling(storyId: story.id, enable: newValue)
                        }
                    }
                    
                    if story.articles.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "newspaper")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No articles found yet")
                                .font(.headline)
                            Text("We'll notify you when new articles are available.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        List(story.articles) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                            } label: {
                                ArticleCardView(article: article)
                            }
                        }
                    }
                }
                .onAppear {
                    // Initialize toggle state from story
                    isPollingEnabled = story.isPolling ?? false
                    
                    // Refresh the story data - wrap in Task
                    Task {
                        await storyTrackingViewModel.refreshStory(storyId: story.id)
                    }
                }
            } else {
                Text("No articles found for \"\(keyword)\" yet.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Story Tracking")
        .onAppear {
            // Wrap the async call in a Task
            Task {
                await storyTrackingViewModel.fetchTrackedStories()
            }
        }
        .refreshable {
            // In a refreshable modifier, we can use await directly
            // since refreshable supports concurrency
            if let story = storyTrackingViewModel.trackedStories.first(where: { $0.keyword == keyword }) {
                await storyTrackingViewModel.refreshStory(storyId: story.id)
            } else {
                await storyTrackingViewModel.fetchTrackedStories()
            }
        }
    }
}
