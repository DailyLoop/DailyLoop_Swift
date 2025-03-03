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
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header info
                HStack {
                    Text(article.source)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(formatDate(article.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Title
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Image
                if let imageUrl = article.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 200)
                    .cornerRadius(8)
                    .clipped()
                }
                
                // Author (if available)
                if let author = article.author, !author.isEmpty {
                    Text("By \(author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.headline)
                    
                    Text(article.summary)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                
                // Actions
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
                    
                    Button {
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    NavigationView {
        ArticleDetailView(article: Article(
            id: "1",
            title: "Sample Article Title That Is Fairly Long For Testing Purposes",
            summary: "This is a sample summary of the article that should span multiple lines to test how the layout appears in the UI. It contains enough text to properly demonstrate word wrapping and line spacing in the ArticleDetailView.",
            source: "The New York Times",
            imageUrl: "https://placehold.it/600x400",
            date: "2023-11-15T10:30:00.000Z",
            url: "https://example.com",
            author: "John Doe"
        ))
        .environmentObject(NewsViewModel())
    }
}
