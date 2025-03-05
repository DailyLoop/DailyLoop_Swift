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

    var body: some View {
        VStack {
            HStack {
                Text("Tracking: \(keyword)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    // Stop tracking the story
                    if let story = storyTrackingViewModel.trackedStories.first(where: { $0.keyword == keyword }) {
                        storyTrackingViewModel.stopTracking(storyId: story.id)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
            .padding()

            if storyTrackingViewModel.isLoading {
                ProgressView()
            } else if let story = storyTrackingViewModel.trackedStories.first(where: { $0.keyword == keyword }) {
                List(story.articles) { article in
                    NavigationLink {
                        ArticleDetailView(article: article)
                    } label: {
                        ArticleCardView(article: article)
                    }
                }
            } else {
                Text("No articles found for \"\(keyword)\" yet.")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Story Tracking")
        .onAppear {
            storyTrackingViewModel.fetchTrackedStories()
        }
    }
}

struct StoryTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoryTrackingView(keyword: "Technology")
                .environmentObject(StoryTrackingViewModel())
        }
    }
}
