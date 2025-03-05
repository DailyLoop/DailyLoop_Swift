//
//  Config.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import Foundation

enum Config {
    enum Supabase {
        // Read values from Info.plist, which gets them from config.xcconfig
        static let url = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? ""
        static let anonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
        static let developmentURL = "https://eegopypfewyqioxirefy.supabase.co" // Fallback for development
        static let developmentAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVlZ29weXBmZXd5cWlveGlyZWZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5OTUyODEsImV4cCI6MjA1NTU3MTI4MX0.C38C1W6Wsjk-p92xFcOyNA5fRclbKFjM5WQsc6ZCZVw" // Fallback for development
    }
}