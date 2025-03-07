//
//  AppObserverView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/7/25.
//
import SwiftUI
import os.log

struct AppObserverView: View {
    @EnvironmentObject var newsViewModel: NewsViewModel
    private let logger = Logger(subsystem: "com.newsflowai.app", category: "AppObserverView")
    
    var body: some View {
        Color.clear // A transparent view
            .onAppear {
                logger.info("AppObserverView appeared – setting up NotificationCenter observers.")
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("UserLoggedIn"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let userId = notification.userInfo?["userId"] as? String {
                        Task {
                            await MainActor.run {
                                newsViewModel.setUserId(userId)
                            }
                        }
                    }
                }
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("UserLoggedOut"),
                    object: nil,
                    queue: .main
                ) { _ in
                    Task {
                        await MainActor.run {
                            newsViewModel.clearUserId()
                        }
                    }
                }
            }
    }
}
