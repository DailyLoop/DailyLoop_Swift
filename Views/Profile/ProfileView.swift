//
//  ProfileView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var userProfile: User?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isApiHealthy = true
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    if let avatarUrl = userProfile?.avatarUrl, !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                    }
                    
                    Text(userProfile?.displayName ?? userProfile?.email ?? authViewModel.user?.email ?? "User")
                        .font(.title)
                        .fontWeight(.bold)
                        
                    if !isApiHealthy {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("API connection issues")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            List {
                Section(header: Text("Account")) {
                    Button {
                        // Edit profile action
                    } label: {
                        HStack {
                            Label("Edit Profile", systemImage: "person")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button {
                        // Notification settings
                    } label: {
                        HStack {
                            Label("Notification Settings", systemImage: "bell")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("App Settings")) {
                    Button {
                        // Appearance settings
                    } label: {
                        HStack {
                            Label("Appearance", systemImage: "paintbrush")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button {
                        // Privacy settings
                    } label: {
                        HStack {
                            Label("Privacy", systemImage: "lock")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button {
                        checkApiHealth()
                    } label: {
                        HStack {
                            Label("Check API Connection", systemImage: "network")
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: isApiHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(isApiHealthy ? .green : .orange)
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Profile")
        .onAppear {
            fetchUserProfile()
            checkApiHealth()
        }
    }
    
    private func fetchUserProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await SupabaseClient.shared.getUserProfile()
                await MainActor.run {
                    self.userProfile = profile
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load profile: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func checkApiHealth() {
        isLoading = true
        
        Task {
            do {
                let isHealthy = try await SupabaseClient.shared.checkApiHealth()
                await MainActor.run {
                    self.isApiHealthy = isHealthy
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isApiHealthy = false
                    self.isLoading = false
                    self.errorMessage = "Connection check failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
