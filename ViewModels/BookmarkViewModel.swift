//
//  BookmarkViewModel.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import Foundation
import Combine

class BookmarkViewModel: ObservableObject {
    @Published var bookmarkedArticles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var isFetching = false  // Add this flag to prevent concurrent fetches
    
    private let supabase = SupabaseClient.shared
    
    func fetchBookmarks() async {
        // Prevent concurrent fetch operations
        guard !isFetching else {
            return
        }
        
        isFetching = true
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let articles = try await supabase.getBookmarks()
            await MainActor.run {
                self.bookmarkedArticles = articles.map { article in
                    var bookmarkedArticle = article
                    bookmarkedArticle.isBookmarked = true
                    return bookmarkedArticle
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
        
        isFetching = false
    }
    
    func removeBookmark(article: Article) async {
        guard let bookmarkId = article.bookmarkId else { return }
        
        do {
            try await supabase.removeBookmark(bookmarkId: bookmarkId)
            await MainActor.run {
                self.bookmarkedArticles.removeAll { $0.id == article.id }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to remove bookmark: \(error.localizedDescription)"
            }
        }
    }
}
