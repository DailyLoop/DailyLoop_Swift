//
//  MainTabView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var newsViewModel = NewsViewModel()
    @StateObject private var bookmarkViewModel = BookmarkViewModel()
    @StateObject private var storyTrackingViewModel = StoryTrackingViewModel()
    
    var body: some View {
        TabView {
            NavigationView {
                HomeView()
                    .environmentObject(newsViewModel)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationView {
                StoriesListView()
                    .environmentObject(storyTrackingViewModel)
            }
            .tabItem {
                Label("Tracking", systemImage: "bell")
            }
            
            NavigationView {
                SearchView()
                    .environmentObject(newsViewModel)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            NavigationView {
                BookmarksView()
                    .environmentObject(bookmarkViewModel)
            }
            .tabItem {
                Label("Bookmarks", systemImage: "bookmark.fill")
            }
            
            NavigationView {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .onAppear {
            // Set up tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Start polling for story tracking
            storyTrackingViewModel.startPolling()
            
            // Load initial data
            Task {
                if !newsViewModel.selectedKeywords.isEmpty {
                    await newsViewModel.search(keyword: newsViewModel.selectedKeywords.joined(separator: " "))
                }
                await bookmarkViewModel.fetchBookmarks()
                await storyTrackingViewModel.fetchTrackedStories()
            }
        }
        .onDisappear {
            // Clean up polling when view disappears
            storyTrackingViewModel.stopPolling()
        }
    }
}
