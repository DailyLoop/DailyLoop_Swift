//
//  User.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
struct User: Codable {
    let id: String
    let email: String?
    let displayName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}
