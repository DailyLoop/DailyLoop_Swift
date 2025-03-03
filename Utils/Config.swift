//
//  Config.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
// Utils/Config.swift
import Foundation

enum Config {
    enum Supabase {
        // Read values from Info.plist, which gets them from config.xcconfig
        static let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
        static let anonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
        static let developmentURL = "https://your-development-url.supabase.co" // Fallback for development
        static let developmentAnonKey = "your-development-key" // Fallback for development
    }
}
