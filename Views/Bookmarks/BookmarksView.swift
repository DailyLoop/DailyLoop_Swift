//
//  BookmarksView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var bookmarkViewModel: BookmarkViewModel
    
    var body: some View {
        Group {
            if bookmarkViewModel.isLoading {
                ProgressView()
            } else if bookmarkViewModel.bookmarkedArticles.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 70))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("No bookmarks yet")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Articles you bookmark will appear here")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(bookmarkViewModel.bookmarkedArticles) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            ArticleCardView(article: article)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await bookmarkViewModel.removeBookmark(article: article)
                                }
                            } label: {
                                Label("Remove", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Bookmarks")
        .onAppear {
            Task {
                await bookmarkViewModel.fetchBookmarks()
            }
        }
    }
}
