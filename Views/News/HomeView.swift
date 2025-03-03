//
//  HomeView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    @State private var showSearch = false
    
    var body: some View {
        ZStack {
            if newsViewModel.articles.isEmpty && !newsViewModel.isLoading {
                VStack(spacing: 20) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 70))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("Discover the latest news")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Search for topics or browse trending headlines")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        showSearch = true
                    } label: {
                        Text("Start searching")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .padding(.horizontal)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if !newsViewModel.selectedKeywords.isEmpty {
                            // Keywords chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(newsViewModel.selectedKeywords, id: \.self) { keyword in
                                        Button {
                                            Task {
                                                await newsViewModel.toggleKeyword(keyword)
                                            }
                                        } label: {
                                            HStack {
                                                Text(keyword)
                                                Image(systemName: "xmark")
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        if newsViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(newsViewModel.articles) { article in
                                NavigationLink {
                                    ArticleDetailView(article: article)
                                        .environmentObject(newsViewModel)
                                } label: {
                                    ArticleCardView(article: article)
                                        .environmentObject(newsViewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    if !newsViewModel.selectedKeywords.isEmpty {
                        await newsViewModel.search(keyword: newsViewModel.selectedKeywords.joined(separator: " "))
                    }
                }
            }
        }
        .navigationTitle("NewsFlow")
        .navigationBarItems(trailing: Button(action: {
            showSearch = true
        }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
        })
        .sheet(isPresented: $showSearch) {
            SearchView()
                .environmentObject(newsViewModel)
        }
    }
}
