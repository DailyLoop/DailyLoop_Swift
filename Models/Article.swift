//
//  Article.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

struct Article: Identifiable, Codable {
    let id: String
    let title: String
    let summary: String
    let source: String
    let imageUrl: String?
    let date: String
    let url: String
    let author: String?
    var isBookmarked: Bool = false
    var bookmarkId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, summary, source, url, author
        case imageUrl = "image"
        case date = "published_at"
        case bookmarkId = "bookmark_id"
    }
}
