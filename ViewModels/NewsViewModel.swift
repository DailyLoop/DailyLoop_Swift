//
//  NewsViewModel.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
import Foundation
import Combine

class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedKeywords: [String] = []
    
    private let supabase = SupabaseClient.shared
    private var sessionId = UUID().uuidString
    
    func search(keyword: String) async {
        if !selectedKeywords.contains(keyword) {
            selectedKeywords.append(keyword)
        }
        
        await fetchNews()
    }
    
    func toggleKeyword(_ keyword: String) async {
        if selectedKeywords.contains(keyword) {
            selectedKeywords.removeAll { $0 == keyword }
        } else {
            selectedKeywords.append(keyword)
        }
        
        await fetchNews()
    }
    
    private func fetchNews() async {
        guard !selectedKeywords.isEmpty else {
            await MainActor.run {
                self.articles = []
            }
            return
        }
        
        let searchQuery = selectedKeywords.joined(separator: " ")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let articles = try await supabase.fetchNews(
                keyword: searchQuery,
                sessionId: sessionId
            )
            
            await MainActor.run {
                self.articles = articles
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func bookmark(article: Article) async {
        guard let index = articles.firstIndex(where: { $0.id == article.id }) else { return }
        
        do {
            if article.isBookmarked, let bookmarkId = article.bookmarkId {
                try await supabase.removeBookmark(bookmarkId: bookmarkId)
                
                await MainActor.run {
                    var updatedArticle = article
                    updatedArticle.isBookmarked = false
                    updatedArticle.bookmarkId = nil
                    articles[index] = updatedArticle
                }
            } else {
                let bookmarkId = try await supabase.addBookmark(newsId: article.id)
                
                await MainActor.run {
                    var updatedArticle = article
                    updatedArticle.isBookmarked = true
                    updatedArticle.bookmarkId = bookmarkId
                    articles[index] = updatedArticle
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update bookmark: \(error.localizedDescription)"
            }
        }
    }
}
