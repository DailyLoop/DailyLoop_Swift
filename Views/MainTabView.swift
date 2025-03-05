//
//  MainTabView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Provide default initializers for these view models
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
                StoryTrackingView(keyword: "Technology")
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
            // Customize tab bar appearance if needed
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Example of loading data when the tab view appears
            Task {
                if !newsViewModel.selectedKeywords.isEmpty {
                    await newsViewModel.search(keyword: newsViewModel.selectedKeywords.joined(separator: " "))
                }
                await bookmarkViewModel.fetchBookmarks()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
