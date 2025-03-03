//
//  SearchView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
import SwiftUI

struct SearchView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private let searchSuggestions = [
        "Politics", "Technology", "Climate Change", "Science",
        "Health", "Business", "Sports", "Entertainment"
    ]
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for news...", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit {
                        if !searchText.isEmpty {
                            Task {
                                await newsViewModel.search(keyword: searchText)
                                searchText = ""
                            }
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Suggested topics
            if searchText.isEmpty && newsViewModel.articles.isEmpty {
                VStack(alignment: .leading) {
                    Text("Suggested Topics")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                            ForEach(searchSuggestions, id: \.self) { suggestion in
                                Button {
                                    Task {
                                        await newsViewModel.search(keyword: suggestion)
                                    }
                                } label: {
                                    Text(suggestion)
                                        .foregroundColor(.primary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                // Search results
                ScrollView {
                    if newsViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if !newsViewModel.articles.isEmpty {
                        LazyVStack(spacing: 16) {
                            ForEach(newsViewModel.articles) { article in
                                NavigationLink {
                                    ArticleDetailView(article: article)
                                        .environmentObject(newsViewModel)
                                } label: {
                                    ArticleCardView(article: article)
                                        .environmentObject(newsViewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    } else if !newsViewModel.selectedKeywords.isEmpty {
                        Text("No results found")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
}
