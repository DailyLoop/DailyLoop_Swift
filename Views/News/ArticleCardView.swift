//
//  ArticleCardView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct ArticleCardView: View {
    let article: Article
    @EnvironmentObject var newsViewModel: NewsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(article.source)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(formatDate(article.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(article.title)
                .font(.headline)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            if let imageUrl = article.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 180)
                .cornerRadius(8)
                .clipped()
            }
            
            Text(article.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Spacer()
                
                Button {
                    Task {
                        await newsViewModel.bookmark(article: article)
                    }
                } label: {
                    Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                        .foregroundColor(article.isBookmarked ? .blue : .gray)
                        .font(.system(size: 18))
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        return dateString.components(separatedBy: "T").first ?? dateString
    }
}
