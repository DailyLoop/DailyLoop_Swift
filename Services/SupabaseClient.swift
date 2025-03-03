//
//  SupabaseClient.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
import Foundation
import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let client: SupabaseClient
    
    private init() {
        // Get configuration from Config.swift
        let supabaseUrl = Config.Supabase.url.isEmpty
            ? Config.Supabase.developmentURL
            : Config.Supabase.url
            
        let supabaseKey = Config.Supabase.anonKey.isEmpty
            ? Config.Supabase.developmentAnonKey
            : Config.Supabase.anonKey
        
        guard let url = URL(string: supabaseUrl) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
    
    // Authentication methods
    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        return response.user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        return response.user
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // News API methods
    func fetchNews(keyword: String, sessionId: String) async throws -> [Article] {
        let response = try await client.functions.invoke(
            functionName: "fetchNews",
            invokeOptions: .init(
                body: ["keyword": keyword, "session_id": sessionId]
            )
        )
        
        let decoder = JSONDecoder()
        return try decoder.decode([Article].self, from: response.data)
    }
    
    // Bookmark methods
    func addBookmark(newsId: String) async throws -> String {
        let response = try await client.functions.invoke(
            functionName: "addBookmark",
            invokeOptions: .init(body: ["news_id": newsId])
        )
        
        let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any]
        guard let bookmarkId = json?["id"] as? String else {
            throw NSError(domain: "BookmarkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract bookmark ID"])
        }
        return bookmarkId
    }
    
    func removeBookmark(bookmarkId: String) async throws {
        _ = try await client.functions.invoke(
            functionName: "removeBookmark",
            invokeOptions: .init(body: ["bookmark_id": bookmarkId])
        )
    }
    
    func getBookmarks() async throws -> [Article] {
        let response = try await client.functions.invoke(
            functionName: "getBookmarks",
            invokeOptions: nil
        )
        
        let decoder = JSONDecoder()
        return try decoder.decode([Article].self, from: response.data)
    }
}
