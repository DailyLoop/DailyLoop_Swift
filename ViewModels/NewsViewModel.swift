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
    
    // Persist sessionId using UserDefaults so it lasts across launches.
    private var sessionId: String {
        if let existing = UserDefaults.standard.string(forKey: "news_session_id") {
            return existing
        } else {
            let newSession = UUID().uuidString
            UserDefaults.standard.set(newSession, forKey: "news_session_id")
            return newSession
        }
    }
    
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
            await MainActor.run { self.articles = [] }
            return
        }
        
        let searchQuery = selectedKeywords.joined(separator: " ")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedArticles = try await supabase.fetchNews(keyword: searchQuery, sessionId: sessionId)
            await MainActor.run {
                self.articles = fetchedArticles
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
                    var updated = article
                    updated.isBookmarked = false
                    updated.bookmarkId = nil
                    articles[index] = updated
                }
            } else {
                let bookmarkId = try await supabase.addBookmark(newsId: article.id)
                await MainActor.run {
                    var updated = article
                    updated.isBookmarked = true
                    updated.bookmarkId = bookmarkId
                    articles[index] = updated
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update bookmark: \(error.localizedDescription)"
            }
        }
    }
}
