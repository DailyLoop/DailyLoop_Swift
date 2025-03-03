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
    
    private let supabase = SupabaseClient.shared
    
    func fetchBookmarks() async {
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
    }
    
    func removeBookmark(article: Article) async {
        guard let bookmarkId = article.bookmarkId else { return }
        
        do {
            try await supabase.removeBookmark(bookmarkId: bookmarkId)
            
            await MainActor.run {
                bookmarkedArticles.removeAll { $0.id == article.id }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to remove bookmark: \(error.localizedDescription)"
            }
        }
    }
}
