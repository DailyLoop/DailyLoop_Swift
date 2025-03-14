//
//  StoriesListView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/10/25.
//

import SwiftUI

struct StoriesListView: View {
    @EnvironmentObject var storyTrackingViewModel: StoryTrackingViewModel
    @State private var showAddStorySheet = false
    @State private var newKeyword = ""
    
    var body: some View {
        Group {
            if storyTrackingViewModel.isLoading {
                ProgressView()
            } else if storyTrackingViewModel.trackedStories.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 70))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("No tracked stories")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track topics to get updates on evolving news stories")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        showAddStorySheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Track a story")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            } else {
                List {
                    ForEach(storyTrackingViewModel.trackedStories) { story in
                        NavigationLink(destination: StoryTrackingView(keyword: story.keyword)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(story.keyword)
                                        .font(.headline)
                                    
                                    Text("\(story.articles.count) articles")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                // Wrap in Task
                                Task {
                                    await storyTrackingViewModel.stopTracking(storyId: story.id)
                                }
                            } label: {
                                Label("Stop Tracking", systemImage: "bell.slash")
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Tracked Stories")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddStorySheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddStorySheet) {
            VStack(spacing: 20) {
                Text("Track a New Story")
                    .font(.title)
                    .fontWeight(.bold)
                
                TextField("Enter keyword or topic", text: $newKeyword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button {
                    if !newKeyword.isEmpty {
                        // Wrap in Task
                        Task {
                            await storyTrackingViewModel.startTracking(keyword: newKeyword)
                            newKeyword = ""
                            showAddStorySheet = false
                        }
                    }
                } label: {
                    Text("Start Tracking")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(newKeyword.isEmpty)
                
                Button {
                    showAddStorySheet = false
                } label: {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .presentationDetents([.medium])
        }
        .onAppear {
            // Wrap in Task
            Task {
                await storyTrackingViewModel.fetchTrackedStories()
            }
        }
        .refreshable {
            // Can use await directly in refreshable
            await storyTrackingViewModel.fetchTrackedStories()
        }
    }
}
