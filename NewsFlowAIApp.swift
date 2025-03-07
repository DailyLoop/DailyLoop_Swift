//
//  NewsFlowAIApp.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var newsViewModel = NewsViewModel()
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    @StateObject private var storyTrackingViewModel = StoryTrackingViewModel()

    // Remove observer registration from init:
    init() {
        // We no longer access our state objects in init.
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                // Attach the observer view so that its onAppear is called.
                AppObserverView()
                    .environmentObject(newsViewModel)
            }
        }
    }
}
