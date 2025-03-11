//
//  ArticleDetailView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var storyTrackingViewModel: StoryTrackingViewModel
    @Environment(\.openURL) private var openURL
    @State private var isTrackingAlertShown = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Your existing view code
                
                HStack {
                    Button {
                        if let url = URL(string: article.url) {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "safari")
                            Text("Read full article")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Story tracking button
                    Button {
                        isTrackingAlertShown = true
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .alert("Track This Story", isPresented: $isTrackingAlertShown) {
                        Button("Track") {
                            let keyword = storyTrackingViewModel.extractMainKeyword(from: article.title)
                            // Wrap in Task since this is an async call in a non-async context
                            Task {
                                await storyTrackingViewModel.startTracking(keyword: keyword, sourceArticleId: article.id)
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Would you like to track stories related to this topic?")
                    }
                    
                    Button {
                        // Wrap in Task
                        Task {
                            await newsViewModel.bookmark(article: article)
                        }
                    } label: {
                        Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 22))
                            .foregroundColor(article.isBookmarked ? .blue : .gray)
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: URL(string: article.url) ?? URL(string: "https://newsflow.app")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Your existing date formatting code
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
}
