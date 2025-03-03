//
//  Conifg.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
// Utils/Config.swift

import Foundation

enum Config {
    // MARK: - Supabase Configuration
    enum Supabase {
        static let url = Config.environmentVariable(named: "SUPABASE_URL")
        static let anonKey = Config.environmentVariable(named: "SUPABASE_ANON_KEY")
        
        // Backup hardcoded values for development (remove for production)
        static let developmentURL = "https://eegopypfewyqioxirefy.supabase.co"
        static let developmentAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlsZiI6ImVlZ29weXBmZXd5cWlveGlyZWZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5OTUyODEsImV4cCI6MjA1NTU3MTI4MX0.C38C1W6Wsjk-p92xFcOyNA5fRclbKFjM5WQsc6ZCZVw"
    }
    
    // MARK: - API Configuration
    enum API {
        static let baseURL = "http://localhost:5001"  // Match your current backend
        
        enum Endpoints {
            static let fetchNews = "/api/news/fetch"
            static let processNews = "/api/news/process"
        }
    }
    
    // MARK: - Helper Methods
    static func environmentVariable(named name: String) -> String {
        // First check Info.plist for configuration
        if let value = Bundle.main.infoDictionary?[name] as? String {
            return value
        }
        
        // Then check environment variables
        if let value = ProcessInfo.processInfo.environment[name] {
            return value
        }
        
        // Return empty string if not found
        return ""
    }
    
    // For checking if we're in debug/development mode
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}
