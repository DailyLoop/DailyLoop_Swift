//
// Services/SupabaseClient.swift
//
import Foundation
import Supabase
import SwiftUI

class SupabaseClient {
    static let shared = SupabaseClient()
    
    let client: Supabase.SupabaseClient
    
    private init() {
        let supabaseUrl = Config.Supabase.url.isEmpty ? Config.Supabase.developmentURL : Config.Supabase.url
        let supabaseKey = Config.Supabase.anonKey.isEmpty ? Config.Supabase.developmentAnonKey : Config.Supabase.anonKey
        
        guard let url = URL(string: supabaseUrl) else {
            fatalError("Invalid Supabase URL")
        }
        self.client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(email: email, password: password)
        let supabaseUser = response.user
        
        var displayName: String? = nil
        if let anyJSON = supabaseUser.userMetadata["display_name"] {
            if let stringValue = anyJSON.stringValue {
                displayName = stringValue
            }
        }

        var avatarUrl: String? = nil
        if let anyJSON = supabaseUser.userMetadata["avatar_url"] {
            if let stringValue = anyJSON.stringValue {
                avatarUrl = stringValue
            }
        }

        let appUser = User(
            id: supabaseUser.id.uuidString,
            email: supabaseUser.email,
            displayName: displayName,
            avatarUrl: avatarUrl
        )
        return appUser
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(email: email, password: password)
        let supabaseUser = response.user
        
        var displayName: String? = nil
        if let anyJSON = supabaseUser.userMetadata["display_name"] {
            if let stringValue = anyJSON.stringValue {
                displayName = stringValue
            }
        }
        
        var avatarUrl: String? = nil
        if let anyJSON = supabaseUser.userMetadata["avatar_url"] {
            if let stringValue = anyJSON.stringValue {
                avatarUrl = stringValue
            }
        }
        let appUser = User(
            id: supabaseUser.id.uuidString,
            email: supabaseUser.email,
            displayName: displayName,
            avatarUrl: avatarUrl
        )
        return appUser
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // MARK: - News API Methods
    
    func fetchNews(keyword: String, sessionId: String) async throws -> [Article] {
        guard let url = URL(string: "\(Config.Supabase.url)/api/news/fetch?keyword=\(keyword)&session_id=\(sessionId)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // If needed, add Authorization headers:
        // request.addValue("Bearer \(someAuthToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let articles = try decoder.decode([Article].self, from: data)
        return articles
    }
    
    // MARK: - Bookmark Methods
    
    func addBookmark(newsId: String) async throws -> String {
        guard let url = URL(string: "\(Config.Supabase.url)/api/bookmarks/") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["news_id": newsId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bookmarkId = json?["data"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        return bookmarkId
    }
    
    func removeBookmark(bookmarkId: String) async throws {
        guard let url = URL(string: "\(Config.Supabase.url)/api/bookmarks/\(bookmarkId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func getBookmarks() async throws -> [Article] {
        guard let url = URL(string: "\(Config.Supabase.url)/api/bookmarks/") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let articles = try decoder.decode([Article].self, from: data)
        return articles
    }
    
    // Optional Summarization
    func fetchSummary(for articleText: String) async throws -> String {
        guard let url = URL(string: "\(Config.Supabase.url)/summarize") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["article_text": articleText]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let summary = json?["summary"] as? String {
            return summary
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
    
    // MARK: - Story Tracking Methods
    
    /// A small helper struct for decoding the createTrakedStory response if your backend returns { "status": "...", "data": { ... story ... } }
    struct TrackedStoryResponse: Codable {
        let status: String
        let data: TrackedStory
    }
    
    /// Fetch all tracked stories for the current user
    func fetchTrackedStories() async throws -> [TrackedStory] {
        guard let url = URL(string: "\(Config.Supabase.url)/api/story_tracking/user") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // If needed, add JWT token header
        // request.addValue("Bearer <token>", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let stories = try decoder.decode([TrackedStory].self, from: data)
        return stories
    }
    
    /// Create a new tracked story
    func createTrackedStory(keyword: String, sourceArticleId: String? = nil) async throws -> TrackedStory {
        guard let url = URL(string: "\(Config.Supabase.url)/api/story_tracking") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Adjust request body to match your backend's expected JSON
        let body: [String: Any] = [
            "keyword": keyword,
            "sourceArticleId": sourceArticleId ?? ""
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // If needed, add JWT token header
        // request.addValue("Bearer <token>", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        // Typically creation returns 201, but confirm with your backend
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let trackedStoryResponse = try decoder.decode(TrackedStoryResponse.self, from: data)
        return trackedStoryResponse.data
    }
    
    /// Delete a tracked story by ID
    func deleteTrackedStory(storyId: String) async throws {
        guard let url = URL(string: "\(Config.Supabase.url)/api/story_tracking/\(storyId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // If needed, add JWT token header
        // request.addValue("Bearer <token>", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}
