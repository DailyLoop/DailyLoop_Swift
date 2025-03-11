//
//  TrackedStory.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/5/25.
//
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
}
