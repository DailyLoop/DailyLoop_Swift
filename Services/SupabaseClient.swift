//
// Services/NewsFlowSupabaseClient.swift
//
import Foundation
import Supabase
import SwiftUI
import os.log

// Custom error types for better error handling
enum SupabaseClientError: Error {
    case invalidURL
    case authenticationFailed(String)
    case networkError(Error)
    case decodingError(Error)
    case responseError(Int, String?)
    case missingData
    case unexpectedError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .responseError(let code, let message):
            return "Server error (\(code)): \(message ?? "No details provided")"
        case .missingData:
            return "Required data missing from response"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        }
    }
}

class SupabaseClient {
    static let shared = SupabaseClient()
    
    let client: Supabase.SupabaseClient
    private let logger = Logger(subsystem: "com.newsflowai.app", category: "SupabaseClient")
    
    private init() {
        logger.info("Initializing SupabaseClient")
        
        let supabaseUrl = Config.Supabase.url.isEmpty ? Config.Supabase.developmentURL : Config.Supabase.url
        let supabaseKey = Config.Supabase.anonKey.isEmpty ? Config.Supabase.developmentAnonKey : Config.Supabase.anonKey
        
        logger.debug("Using Supabase URL: \(supabaseUrl)")
        
        guard let url = URL(string: supabaseUrl) else {
            logger.error("Invalid Supabase URL provided: \(supabaseUrl)")
            fatalError("Invalid Supabase URL")
        }
        
        // Here we reference the official Supabase struct (Supabase.SupabaseClient).
        // Our class is now named differently to avoid conflict.
        self.client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
        logger.info("SupabaseClient successfully initialized")
    }
    
    // MARK: - Authentication Methods
    func signUp(email: String, password: String) async throws -> User {
        logger.info("Attempting to sign up user with email: \(email)")
        
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            let supabaseUser = response.user
            
            logger.info("User signed up successfully with ID: \(supabaseUser.id)")
            logger.debug("Processing user metadata")
            
            var displayName: String? = nil
            if let anyJSON = supabaseUser.userMetadata["display_name"],
               let stringValue = anyJSON.stringValue {
                displayName = stringValue
            }
            
            var avatarUrl: String? = nil
            if let anyJSON = supabaseUser.userMetadata["avatar_url"],
               let stringValue = anyJSON.stringValue {
                avatarUrl = stringValue
            }
            
            // Extract the 'sub' value from userMetadata as the user ID
            let userId: String
            if let subValue = supabaseUser.userMetadata["sub"]?.stringValue {
                userId = subValue
                logger.debug("Using 'sub' value from userMetadata as user ID: \(userId)")
            } else {
                userId = supabaseUser.id.uuidString
                logger.debug("Falling back to default ID: \(userId)")
            }
            
            let user = User(
                id: userId,
                email: supabaseUser.email,
                displayName: displayName,
                avatarUrl: avatarUrl
            )
            
            logger.info("User object created successfully")
            return user
        } catch {
            logger.error("Sign up failed: \(error.localizedDescription)")
            throw SupabaseClientError.authenticationFailed("Failed to sign up: \(error.localizedDescription)")
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        logger.info("Attempting to sign in user with email: \(email)")
        
        do {
            let response = try await client.auth.signIn(email: email, password: password)
            let supabaseUser = response.user
            
            // Brute force approach to log the entire response
            logger.info("Auth response: \(String(describing: response))")
            
            logger.info("User signed in successfully with ID: \(supabaseUser.id)")
            
            var displayName: String? = nil
            if let anyJSON = supabaseUser.userMetadata["display_name"],
               let stringValue = anyJSON.stringValue {
                displayName = stringValue
                logger.debug("Found display name in metadata: \(displayName!)")
            }
            
            var avatarUrl: String? = nil
            if let anyJSON = supabaseUser.userMetadata["avatar_url"],
               let stringValue = anyJSON.stringValue {
                avatarUrl = stringValue
                logger.debug("Found avatar URL in metadata: \(avatarUrl!)")
            }
            
            // Extract the 'sub' value from userMetadata as the user ID
            let userId: String
            if let subValue = supabaseUser.userMetadata["sub"]?.stringValue {
                userId = subValue
                logger.debug("Using 'sub' value from userMetadata as user ID: \(userId)")
            } else {
                userId = supabaseUser.id.uuidString
                logger.debug("Falling back to default ID: \(userId)")
            }
            
            let user = User(
                id: userId,
                email: supabaseUser.email,
                displayName: displayName,
                avatarUrl: avatarUrl
            )
            
            logger.info("User object created successfully")
            return user
        } catch {
            logger.error("Sign in failed: \(error.localizedDescription)")
            throw SupabaseClientError.authenticationFailed("Failed to sign in: \(error.localizedDescription)")
        }
    }
    
    func signOut() async throws {
        logger.info("Attempting to sign out user")
        
        do {
            try await client.auth.signOut()
            logger.info("User signed out successfully")
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
            throw SupabaseClientError.authenticationFailed("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - News API Methods
    func fetchNews(keyword: String, sessionId: String, userId: String? = nil) async throws -> [Article] {
        logger.info("Fetching news with keyword: \(keyword), sessionId: \(sessionId), userId: \(userId ?? "not provided")")
        
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        
        // Construct URL with user_id if available
        var urlString = "\(Config.API.baseURL)/api/news/fetch?session_id=\(sessionId)"
        
        // Add userId parameter if provided
        if let userId = userId {
            urlString += "&user_id=\(userId)"
        }
        
        // Add keyword parameter (already encoded)
        urlString += "&keyword=\(encodedKeyword)"
        
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL for fetchNews: \(urlString)")
            throw SupabaseClientError.invalidURL
        }
        
        logger.debug("Requesting news from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let endTime = CFAbsoluteTimeGetCurrent()
            logger.debug("News fetch completed in \(String(format: "%.2f", endTime - startTime)) seconds")
            
            // Log the raw response data to debug decoding issues
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Raw response data: \(responseString)")
            } else {
                logger.warning("Could not convert response data to string")
            }
            
            // Process (summarize) articles fetched in this session
            logger.info("Processing articles for session: \(sessionId)")
            guard let processUrl = URL(string: "\(Config.API.baseURL)/api/news/process?session_id=\(sessionId)") else {
                logger.error("Invalid URL for processing news")
                throw SupabaseClientError.invalidURL
            }
            
            var processRequest = URLRequest(url: processUrl)
            processRequest.httpMethod = "POST"
            processRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let processStartTime = CFAbsoluteTimeGetCurrent()
            let (processedData, processResponse) = try await URLSession.shared.data(for: processRequest)
            let processEndTime = CFAbsoluteTimeGetCurrent()
            logger.debug("News processing completed in \(String(format: "%.2f", processEndTime - processStartTime)) seconds")
            
            // Log the processed data response as JSON for debugging
            if let jsonObject = try? JSONSerialization.jsonObject(with: processedData),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                logger.debug("Processed data response: \(jsonString)")
            }
            guard let processHttpResponse = processResponse as? HTTPURLResponse else {
                logger.error("Non-HTTP response received from processing endpoint")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received from processing endpoint")
            }
            
            if processHttpResponse.statusCode != 200 {
                logger.error("Failed to process news, server returned: \(processHttpResponse.statusCode)")
                throw SupabaseClientError.responseError(processHttpResponse.statusCode, "Failed to process news")
            }
            
            // Use the processed data for decoding instead of the original data
            data = processedData
            
            logger.info("Successfully processed articles data")

            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 200 {
                logger.error("Server returned error code: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Bad response from server")
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let articles = try decoder.decode([Article].self, from: processedData)
                logger.info("Successfully decoded \(articles.count) articles")
                return articles
            } catch {
                logger.error("Failed to decode article data: \(error.localizedDescription)")
                throw SupabaseClientError.decodingError(error)
            }
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error during news fetch: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
    
    // MARK: - Bookmark Methods
    func addBookmark(newsId: String) async throws -> String {
        logger.info("Adding bookmark for news ID: \(newsId)")
        
        guard let url = URL(string: "\(Config.API.baseURL)/api/bookmarks/") else {
            logger.error("Invalid URL for addBookmark: \(Config.API.baseURL)/api/bookmarks/")
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["news_id": newsId]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            logger.debug("Sending bookmark POST request")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 200 {
                logger.error("Failed to add bookmark, server returned: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Failed to add bookmark")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let bookmarkId = json?["data"] as? String else {
                    logger.error("Missing bookmarkId in response")
                    throw SupabaseClientError.missingData
                }
                
                logger.info("Successfully added bookmark with ID: \(bookmarkId)")
                return bookmarkId
            } catch {
                logger.error("Failed to parse bookmark response: \(error.localizedDescription)")
                throw SupabaseClientError.decodingError(error)
            }
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error while adding bookmark: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
    
    func removeBookmark(bookmarkId: String) async throws {
        logger.info("Removing bookmark with ID: \(bookmarkId)")
        
        guard let url = URL(string: "\(Config.API.baseURL)/api/bookmarks/\(bookmarkId)") else {
            logger.error("Invalid URL for removeBookmark: \(Config.API.baseURL)/api/bookmarks/\(bookmarkId)")
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            logger.debug("Sending bookmark DELETE request")
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 200 {
                logger.error("Failed to remove bookmark, server returned: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Failed to remove bookmark")
            }
            
            logger.info("Successfully removed bookmark")
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error while removing bookmark: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
    
    func getBookmarks() async throws -> [Article] {
        logger.info("Fetching all bookmarks")
        
        guard let url = URL(string: "\(Config.API.baseURL)/api/bookmarks/") else {
            logger.error("Invalid URL for getBookmarks: \(Config.API.baseURL)/api/bookmarks/")
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logger.debug("Sending bookmarks GET request")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 200 {
                logger.error("Failed to get bookmarks, server returned: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Failed to get bookmarks")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let articles = try decoder.decode([Article].self, from: data)
                logger.info("Successfully fetched \(articles.count) bookmarked articles")
                return articles
            } catch {
                logger.error("Failed to decode bookmarked articles: \(error.localizedDescription)")
                throw SupabaseClientError.decodingError(error)
            }
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error while fetching bookmarks: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
    
    // MARK: - Summarization
    func fetchSummary(for articleText: String) async throws -> String {
        logger.info("Requesting summary for article text (\(articleText.count) characters)")
        
        guard let url = URL(string: "\(Config.API.baseURL)/summarize") else {
            logger.error("Invalid URL for fetchSummary: \(Config.API.baseURL)/summarize")
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["article_text": articleText]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            logger.debug("Sending summarization request")
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let (data, response) = try await URLSession.shared.data(for: request)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            logger.debug("Summary request completed in \(String(format: "%.2f", endTime - startTime)) seconds")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 200 {
                logger.error("Summarization failed, server returned: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Failed to get summary")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let summary = json?["summary"] as? String else {
                    logger.error("Missing summary in response")
                    throw SupabaseClientError.missingData
                }
                
                logger.info("Successfully received summary (\(summary.count) characters)")
                return summary
            } catch {
                logger.error("Failed to parse summary response: \(error.localizedDescription)")
                throw SupabaseClientError.decodingError(error)
            }
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error during summarization: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
    
    // MARK: - Story Tracking Methods
    
    struct TrackedStoryResponse: Codable {
        let status: String
        let data: TrackedStory
    }
    
    func fetchTrackedStories() async throws -> [TrackedStory] {
        logger.info("Fetching tracked stories")
        
        guard let url = URL(string: "\(Config.API.baseURL)/api/story_tracking/user") else {
            logger.error("Invalid URL for fetchTrackedStories: \(Config.API.baseURL)/api/story_tracking/user")
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logger.debug("Sending tracked stories GET request")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 200 {
                logger.error("Failed to fetch tracked stories, server returned: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Failed to fetch tracked stories")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let stories = try decoder.decode([TrackedStory].self, from: data)
                logger.info("Successfully fetched \(stories.count) tracked stories")
                return stories
            } catch {
                logger.error("Failed to decode tracked stories: \(error.localizedDescription)")
                throw SupabaseClientError.decodingError(error)
            }
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error while fetching tracked stories: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
    
    func createTrackedStory(keyword: String, sourceArticleId: String? = nil) async throws -> TrackedStory {
        logger.info("Creating tracked story for keyword: \(keyword), sourceArticleId: \(sourceArticleId ?? "none")")
        
        guard let url = URL(string: "\(Config.API.baseURL)/api/story_tracking") else {
            logger.error("Invalid URL for createTrackedStory: \(Config.API.baseURL)/api/story_tracking")
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "keyword": keyword,
            "sourceArticleId": sourceArticleId ?? ""
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            logger.debug("Sending tracked story POST request")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 201 {
                logger.error("Failed to create tracked story, server returned: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Failed to create tracked story")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let trackedStoryResponse = try decoder.decode(TrackedStoryResponse.self, from: data)
                logger.info("Successfully created tracked story with ID: \(trackedStoryResponse.data.id)")
                return trackedStoryResponse.data
            } catch {
                logger.error("Failed to decode tracked story response: \(error.localizedDescription)")
                throw SupabaseClientError.decodingError(error)
            }
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error while creating tracked story: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
    
    func deleteTrackedStory(storyId: String) async throws {
        logger.info("Deleting tracked story with ID: \(storyId)")
        
        guard let url = URL(string: "\(Config.API.baseURL)/api/story_tracking/\(storyId)") else {
            logger.error("Invalid URL for deleteTrackedStory: \(Config.API.baseURL)/api/story_tracking/\(storyId)")
            throw SupabaseClientError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        do {
            logger.debug("Sending tracked story DELETE request")
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Non-HTTP response received")
                throw SupabaseClientError.responseError(0, "Non-HTTP response received")
            }
            
            if httpResponse.statusCode != 200 {
                logger.error("Failed to delete tracked story, server returned: \(httpResponse.statusCode)")
                throw SupabaseClientError.responseError(httpResponse.statusCode, "Failed to delete tracked story")
            }
            
            logger.info("Successfully deleted tracked story")
        } catch let error as SupabaseClientError {
            throw error
        } catch {
            logger.error("Network error while deleting tracked story: \(error.localizedDescription)")
            throw SupabaseClientError.networkError(error)
        }
    }
}
