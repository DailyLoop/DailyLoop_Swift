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
