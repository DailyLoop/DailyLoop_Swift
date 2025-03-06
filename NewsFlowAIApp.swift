//
//  NewsFlowAIApp.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var newsViewModel = NewsViewModel()
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    @StateObject private var storyTrackingViewModel = StoryTrackingViewModel()
    
    init() {
        // Set up observers for auth state changes
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UserLoggedIn"), object: nil, queue: .main) { [self] notification in
            if let userId = notification.userInfo?["userId"] as? String {
                newsViewModel.setUserId(userId)
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("UserLoggedOut"), object: nil, queue: .main) { [self] _ in
            newsViewModel.clearUserId()
        }
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(newsViewModel)
                    .environmentObject(bookmarkViewModel)
                    .environmentObject(storyTrackingViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
