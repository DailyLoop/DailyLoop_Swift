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
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Initialize data
            Task {
                if newsViewModel.articles.isEmpty && !newsViewModel.selectedKeywords.isEmpty {
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

