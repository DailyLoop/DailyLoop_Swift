//
//  AuthViewModel.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseClient.shared
    
    func signIn(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let user = try await supabase.signIn(email: email, password: password)
            await MainActor.run {
                self.user = user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String?) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let user = try await supabase.signUp(email: email, password: password)
            // Optionally update display name via your backend
            await MainActor.run {
                self.user = user
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            try await supabase.signOut()
            await MainActor.run {
                self.user = nil
                self.isAuthenticated = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func checkSession() async {
        // Implement session checking if needed
    }
}
