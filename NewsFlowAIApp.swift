//  Created by Akalpit Dawkhar on 3/3/25.
//

// NewsFlowApp.swift - Entry point
import SwiftUI

@main
struct NewsFlowApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

