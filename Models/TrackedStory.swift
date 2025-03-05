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
    var articles: [Article]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case keyword
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case articles
    }
}
