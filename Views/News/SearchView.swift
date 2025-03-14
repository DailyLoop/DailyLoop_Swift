//
//  SearchView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI
import os.log

struct SearchView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    // Create a logger instance for this view
    private let logger = Logger(subsystem: "com.newsflowai.app", category: "SearchView")
    
    private let searchSuggestions = [
        "Politics", "Technology", "Climate Change", "Science",
        "Health", "Business", "Sports", "Entertainment"
    ]
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search for news...", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit {
                        if !searchText.isEmpty {
                            logger.info("User submitted search: \(searchText)")
                            Task {
                                await newsViewModel.search(keyword: searchText)
                                logger.info("Search completed for: \(searchText)")
                                searchText = ""
                            }
                        } else {
                            logger.info("Empty search submitted - ignoring")
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        logger.info("Search text cleared")
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
                                    logger.info("Suggestion selected: \(suggestion)")
                                    Task {
                                        await newsViewModel.search(keyword: suggestion)
                                        logger.info("Suggestion search completed: \(suggestion)")
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
                .onAppear {
                    logger.info("Showing search suggestions")
                }
            } else {
                ScrollView {
                    if newsViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .onAppear {
                                logger.info("Loading search results")
                            }
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
                                .onAppear {
                                    logger.debug("Displaying article: \(article.title)")
                                    
                                    // Log the last article appearing (for pagination tracking)
                                    if article.id == newsViewModel.articles.last?.id {
                                        logger.info("Reached end of current results. Count: \(newsViewModel.articles.count)")
                                    }
                                }
                            }
                        }
                        .padding()
                        .onAppear {
                            logger.info("Displaying \(newsViewModel.articles.count) search results")
                        }
                    } else if !newsViewModel.selectedKeywords.isEmpty {
                        Text("No results found")
                            .foregroundColor(.secondary)
                            .padding()
                            .onAppear {
                                logger.warning("No results found for keywords: \(newsViewModel.selectedKeywords.joined(separator: ", "))")
                            }
                    }
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            logger.info("SearchView appeared")
        }
        .onDisappear {
            logger.info("SearchView disappeared")
        }
    }
}
