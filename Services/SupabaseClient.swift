// Services/SupabaseClient.swift
import Foundation
import Supabase

// This needs to be a class (not a struct) to have a shared singleton instance
class SupabaseClient {
    // This static property is what your ViewModels are trying to access
    static let shared = SupabaseClient()
    
    private let client: Supabase.SupabaseClient
    
    private init() {
        // Get configuration from Config.swift
        let supabaseUrl = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
        let supabaseKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
        
        // Use fallback values if the Info.plist values are empty
        let finalUrl = supabaseUrl.isEmpty ? "https://your-dev-url.supabase.co" : supabaseUrl
        let finalKey = supabaseKey.isEmpty ? "your-dev-key" : supabaseKey
        
        guard let url = URL(string: finalUrl) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: finalKey
        )
    }
    
    // Authentication methods
    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        // Convert Supabase user to your app's User model
        let appUser = User(
            id: response.user.id.uuidString,
            email: response.user.email,
            displayName: nil,
            avatarUrl: nil
        )
        
        return appUser
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        // Convert Supabase user to your app's User model
        let appUser = User(
            id: response.user.id.uuidString,
            email: response.user.email,
            displayName: nil,
            avatarUrl: nil
        )
        
        return appUser
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    // News API methods
    func fetchNews(keyword: String, sessionId: String) async throws -> [Article] {
        // Mock implementation for now
        return []
    }
    
    // Bookmark methods
    func addBookmark(newsId: String) async throws -> String {
        // Mock implementation for now
        return UUID().uuidString
    }
    
    func removeBookmark(bookmarkId: String) async throws {
        // Mock implementation for now
    }
    
    func getBookmarks() async throws -> [Article] {
        // Mock implementation for now
        return []
    }
}
