//
//  TrackedStory.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/5/25.
//
import Foundation
struct TrackedStory: Codable, Identifiable {
    let id: String
    let userId: String
    let keyword: String
    let createdAt: String
    let lastUpdated: String
    let isPolling: Bool?
    let lastPolledAt: String?
    var articles: [Article]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case keyword
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case isPolling = "is_polling"
        case lastPolledAt = "last_polled_at"
        case articles
    }
    
    // Custom Article structure for nested decoding
    struct ArticleWrapper: Codable {
        let addedAt: String
        let article: Article
        
        enum CodingKeys: String, CodingKey {
            case addedAt = "added_at"
            case id, content, createdAt, image, publishedAt, source, summary, title, url, author
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            addedAt = try container.decode(String.self, forKey: .addedAt)
            
            // Decode the article fields directly from this container
            let id = try container.decode(String.self, forKey: .id)
            let title = try container.decode(String.self, forKey: .title)
            let summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
            let source = try container.decode(String.self, forKey: .source)
            let image = try container.decodeIfPresent(String.self, forKey: .image)
            let publishedAt = try container.decode(String.self, forKey: .publishedAt)
            let url = try container.decode(String.self, forKey: .url)
            let author = try container.decodeIfPresent(String.self, forKey: .author)
            let _ = try container.decodeIfPresent(String.self, forKey: .content)
            let _ = try container.decodeIfPresent(String.self, forKey: .createdAt)
            
            article = Article(
                id: id,
                title: title,
                summary: summary,
                source: source,
                imageUrl: image,
                date: publishedAt,
                url: url,
                author: author
            )
        }
        
        // Add encode method to make ArticleWrapper fully conform to Codable
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(addedAt, forKey: .addedAt)
            try container.encode(article.id, forKey: .id)
            try container.encode(article.title, forKey: .title)
            try container.encode(article.summary, forKey: .summary)
            try container.encode(article.source, forKey: .source)
            try container.encode(article.imageUrl, forKey: .image)
            try container.encode(article.date, forKey: .publishedAt)
            try container.encode(article.url, forKey: .url)
            try container.encodeIfPresent(article.author, forKey: .author)
        }
    }
    
    // Add custom initializer to handle potential null values or missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Use decodeIfPresent for all fields to make the model more resilient
        do {
            id = try container.decode(String.self, forKey: .id)
        } catch {
            // If we can't decode the ID, this is a critical error
            throw error
        }
        
        // For other fields, provide default values if they're missing
        do {
            userId = try container.decode(String.self, forKey: .userId)
        } catch {
            // If userId is missing, use a placeholder
            userId = "unknown"
        }
        
        do {
            keyword = try container.decode(String.self, forKey: .keyword)
        } catch {
            // If keyword is missing, use a placeholder
            keyword = "unknown"
        }
        
        do {
            createdAt = try container.decode(String.self, forKey: .createdAt)
        } catch {
            // If createdAt is missing, use current date string
            createdAt = ISO8601DateFormatter().string(from: Date())
        }
        
        do {
            lastUpdated = try container.decode(String.self, forKey: .lastUpdated)
        } catch {
            // If lastUpdated is missing, use current date string
            lastUpdated = ISO8601DateFormatter().string(from: Date())
        }
        
        // Handle optional fields that might be null or missing
        isPolling = try container.decodeIfPresent(Bool.self, forKey: .isPolling)
        lastPolledAt = try container.decodeIfPresent(String.self, forKey: .lastPolledAt)
        
        // Try to decode articles as ArticleWrapper array first
        if let articleWrappers = try? container.decodeIfPresent([ArticleWrapper].self, forKey: .articles) {
            articles = articleWrappers.map { $0.article }
        } else {
            // Fall back to direct Article array decoding
            articles = try container.decodeIfPresent([Article].self, forKey: .articles) ?? []
        }
    }
    
    // Add a default initializer for creating instances programmatically
    init(id: String, userId: String, keyword: String, createdAt: String, lastUpdated: String, 
         isPolling: Bool? = nil, lastPolledAt: String? = nil, articles: [Article] = []) {
        self.id = id
        self.userId = userId
        self.keyword = keyword
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.isPolling = isPolling
        self.lastPolledAt = lastPolledAt
        self.articles = articles
    }
}
