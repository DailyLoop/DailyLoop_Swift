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
    // You can inject these view models here, or let MainTabView create them.
    @StateObject private var newsViewModel = NewsViewModel()
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(newsViewModel)
                    .environmentObject(bookmarkViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
