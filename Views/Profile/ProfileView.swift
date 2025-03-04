//
//  ProfileView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text(authViewModel.user?.displayName ?? authViewModel.user?.email ?? "User")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding()
            
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
    }
}
