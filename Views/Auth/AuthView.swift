//
//  AuthView.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(UIColor.systemBackground), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Background animation
                WavesBackground()
                
                ScrollView {
                    VStack(spacing: 25) {
                        VStack(spacing: 15) {
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("NewsFlow")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Discover and analyze news from multiple sources")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 50)
                        
                        VStack(spacing: 20) {
                            Picker("Mode", selection: $isLogin) {
                                Text("Sign In").tag(true)
                                Text("Create Account").tag(false)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                TextField("Email", text: $email)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(RoundedTextFieldStyle())
                                
                                if !isLogin {
                                    TextField("Display Name", text: $displayName)
                                        .textFieldStyle(RoundedTextFieldStyle())
                                }
                            }
                            .padding(.horizontal)
                            
                            if let errorMessage = authViewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            
                            Button {
                                Task {
                                    if isLogin {
                                        await authViewModel.signIn(email: email, password: password)
                                    } else {
                                        await authViewModel.signUp(email: email, password: password, displayName: displayName)
                                    }
                                }
                            } label: {
                                Text(isLogin ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                            }
                            .disabled(authViewModel.isLoading)
                            
                            if authViewModel.isLoading {
                                ProgressView()
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
