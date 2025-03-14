//
//  NewsViewModel.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import Foundation
import Combine
import os.log

// Define custom error types for NewsViewModel
enum NewsViewModelError: Error {
    case emptyKeywords
    case articleNotFound(String)
    case bookmarkOperationFailed(Error)
    case fetchFailed(Error)
    
    var localizedDescription: String {
        switch self {
        case .emptyKeywords:
            return "No search keywords provided"
        case .articleNotFound(let id):
            return "Article with ID \(id) not found in collection"
        case .bookmarkOperationFailed(let error):
            return "Bookmark operation failed: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch news: \(error.localizedDescription)"
        }
    }
}

@MainActor
class NewsViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedKeywords: [String] = []
    @Published var isHealthy = true
    
    private let supabase = SupabaseClient.shared
    private let logger = Logger(subsystem: "com.newsflowai.app", category: "NewsViewModel")
    
    // Store user ID for API calls
    private var userId: String? {
        return UserDefaults.standard.string(forKey: "user_id")
    }
    
    // Persist sessionId using UserDefaults so it lasts across launches.
    private var sessionId: String {
        if let existing = UserDefaults.standard.string(forKey: "news_session_id") {
            logger.debug("Using existing session ID: \(existing)")
            return existing
        } else {
            let newSession = UUID().uuidString
            logger.info("Creating new session ID: \(newSession)")
            UserDefaults.standard.set(newSession, forKey: "news_session_id")
            if UserDefaults.standard.string(forKey: "news_session_id") == newSession {
                logger.debug("Session ID saved successfully to UserDefaults")
            } else {
                logger.warning("Session ID may not have been saved properly to UserDefaults")
            }
            return newSession
        }
    }
    
    init() {
        logger.info("NewsViewModel initialized")
        
        // Check API health
        Task {
            await checkApiHealth()
        }
    }
    
    func checkApiHealth() async {
        do {
            let healthy = try await supabase.checkApiHealth()
            await MainActor.run {
                self.isHealthy = healthy
            }
            logger.info("API health check: \(healthy ? "OK" : "Unhealthy")")
        } catch {
            await MainActor.run {
                self.isHealthy = false
            }
            logger.warning("API health check failed: \(error.localizedDescription)")
        }
    }
    
    func search(keyword: String) async {
        logger.info("Search requested for keyword: \(keyword)")
        
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Empty keyword provided to search function")
            await MainActor.run {
                self.errorMessage = "Please enter a valid search term"
            }
            return
        }
        
        if !self.selectedKeywords.contains(keyword) {
            self.selectedKeywords.append(keyword)
            logger.debug("Added keyword to selection: \(keyword), total keywords: \(self.selectedKeywords.count)")
        } else {
            logger.debug("Keyword already selected: \(keyword)")
        }
        
        // Track timing for the entire search operation
        let startTime = CFAbsoluteTimeGetCurrent()
        await self.fetchNews()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Total search operation completed in \(String(format: "%.2f", duration))s")
    }
    
    func toggleKeyword(_ keyword: String) async {
        logger.info("Toggle requested for keyword: \(keyword)")
        
        guard !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Attempted to toggle empty keyword")
            return
        }
        
        if self.selectedKeywords.contains(keyword) {
            logger.info("Removing keyword: \(keyword)")
            self.selectedKeywords.removeAll { $0 == keyword }
        } else {
            logger.info("Adding keyword: \(keyword)")
            self.selectedKeywords.append(keyword)
        }
        
        logger.debug("Current keywords after toggle: \(self.selectedKeywords)")
        
        // Track timing for the entire toggle operation
        let startTime = CFAbsoluteTimeGetCurrent()
        await self.fetchNews()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Keyword toggle and fetch completed in \(String(format: "%.2f", duration))s")
    }
    
    private func fetchNews() async {
        guard !self.selectedKeywords.isEmpty else {
            logger.info("No keywords selected, clearing articles")
            await MainActor.run { self.articles = [] }
            return
        }
        
        let searchQuery = self.selectedKeywords.joined(separator: " ")
        logger.info("Fetching news with query: \(searchQuery)")
        
        // Update UI to loading state
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            logger.debug("UI updated to loading state")
        }
        
        do {
            logger.debug("Calling Supabase API for news fetch")
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let fetchedArticles: [Article]
            do {
                // Use the version that returns metadata
                let (articles, _) = try await self.supabase.fetchNewsWithMetadata(
                    keyword: searchQuery,
                    sessionId: self.sessionId,
                    userId: self.userId
                )
                fetchedArticles = articles
                logger.debug("News API called with userId: \(self.userId ?? "not available")")
            } catch {
                logger.error("Supabase API call failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    self.errorMessage = "Failed to fetch news: \(error.localizedDescription)"
                    self.isLoading = false
                    self.articles = [] // Clear articles on error
                    logger.debug("UI updated with error state")
                }
                
                return
            }
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("News fetch completed in \(String(format: "%.2f", duration))s, found \(fetchedArticles.count) articles")
            
            if fetchedArticles.isEmpty {
                logger.info("No articles found for query: \(searchQuery)")
            } else {
                logger.debug("First article title: \(fetchedArticles.first?.title ?? "unknown")")
                logger.debug("Last article title: \(fetchedArticles.last?.title ?? "unknown")")
            }
            
            // Update UI with results
            await MainActor.run {
                self.articles = fetchedArticles
                self.isLoading = false
                logger.debug("UI updated with fetched articles")
            }
        }
    }
    
    func bookmark(article: Article) async {
        logger.info("Bookmark operation requested for article: \(article.id)")
        
        do {
            guard let index = self.articles.firstIndex(where: { $0.id == article.id }) else {
                logger.warning("Attempted to bookmark article not found in collection: \(article.id)")
                throw NewsViewModelError.articleNotFound(article.id)
            }
            
            if article.isBookmarked, let bookmarkId = article.bookmarkId {
                logger.info("Removing bookmark for article: \(article.id), bookmark ID: \(bookmarkId)")
                
                do {
                    try await self.supabase.removeBookmark(bookmarkId: bookmarkId)
                    logger.debug("Bookmark successfully removed from backend")
                    
                    await MainActor.run {
                        var updated = article
                        updated.isBookmarked = false
                        updated.bookmarkId = nil
                        self.articles[index] = updated
                        logger.debug("Article updated after bookmark removal")
                    }
                } catch {
                    logger.error("Failed to remove bookmark from backend: \(error.localizedDescription)")
                    throw NewsViewModelError.bookmarkOperationFailed(error)
                }
            } else {
                logger.info("Adding bookmark for article: \(article.id)")
                
                do {
                    let bookmarkId = try await self.supabase.addBookmark(newsId: article.id)
                    logger.debug("Bookmark successfully added with ID: \(bookmarkId)")
                    
                    await MainActor.run {
                        var updated = article
                        updated.isBookmarked = true
                        updated.bookmarkId = bookmarkId
                        self.articles[index] = updated
                        logger.debug("Article updated with new bookmark ID: \(bookmarkId)")
                    }
                } catch {
                    logger.error("Failed to add bookmark on backend: \(error.localizedDescription)")
                    throw NewsViewModelError.bookmarkOperationFailed(error)
                }
            }
        } catch {
            logger.error("Bookmark operation failed: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Failed to update bookmark: \(error.localizedDescription)"
            }
        }
    }
    
    // Set user ID method for when user logs in
    func setUserId(_ id: String) {
        logger.info("Setting user ID: \(id)")
        UserDefaults.standard.set(id, forKey: "user_id")
    }
    
    // Remove user ID method for logout
    func clearUserId() {
        logger.info("Clearing user ID")
        UserDefaults.standard.removeObject(forKey: "user_id")
    }
    
    // Add a method to get summary for an article text
    func getSummary(for text: String) async throws -> String {
        logger.info("Getting summary for text of length \(text.count)")
        do {
            let summary = try await supabase.fetchSummary(for: text)
            return summary
        } catch {
            logger.error("Error getting summary: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Add a cleanup method for proper lifecycle management
    func cleanup() {
        logger.info("NewsViewModel cleanup initiated")
        // Perform any cleanup operations like cancelling subscriptions
    }
    
    deinit {
        logger.info("NewsViewModel is being deallocated")
    }
}
