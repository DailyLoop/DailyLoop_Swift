import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var storyTrackingViewModel: StoryTrackingViewModel
    @Environment(\.openURL) private var openURL
    @State private var isTrackingAlertShown = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Article image
                if let imageUrl = article.imageUrl,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 250)
                    }
                }
                
                // Article title
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                // Meta data: source and date
                HStack {
                    Text(article.source)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(article.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Article summary
                Text(article.summary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        if let url = URL(string: article.url) {
                            openURL(url)
                        }
                    } label: {
                        Label("Read Full Article", systemImage: "safari")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        isTrackingAlertShown = true
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 22))
                            .foregroundColor(.orange)
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .alert("Track This Story", isPresented: $isTrackingAlertShown) {
                        Button("Track") {
                            let keyword = storyTrackingViewModel.extractMainKeyword(from: article.title)
                            Task {
                                await storyTrackingViewModel.startTracking(keyword: keyword, sourceArticleId: article.id)
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Would you like to track stories related to this topic?")
                    }
                    
                    Button {
                        Task {
                            await newsViewModel.bookmark(article: article)
                        }
                    } label: {
                        Image(systemName: article.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 22))
                            .foregroundColor(article.isBookmarked ? .blue : .gray)
                            .padding(12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: URL(string: article.url) ?? URL(string: "https://newsflow.app")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}
