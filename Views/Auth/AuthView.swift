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
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(UIColor.systemBackground), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating particles effect (similar to your web app)
                WavesBackground()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Logo and app name
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
                        
                        // Auth form
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
                            
                            // Error message
                            if let errorMessage = authViewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            
                            // Sign in/up button
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

// Custom rounded text field style
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

// WavesBackground similar to your web app
struct WavesBackground: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let timeInterval = timeline.date.timeIntervalSince1970
                let amplitude = size.width / 25
                
                context.opacity = 0.1
                
                // Draw 10 wave lines
                for i in 0..<10 {
                    var path = Path()
                    let waveHeight = size.height / 2
                    
                    // Start at the left edge
                    path.move(to: CGPoint(x: 0, y: waveHeight))
                    
                    // Draw the wave
                    for x in stride(from: 0, to: size.width, by: 5) {
                        let frequency = Double(i + 1) / 15.0
                        let phase = timeInterval * frequency
                        
                        let y = waveHeight + amplitude * sin(((2 * .pi) / 200) * x + phase)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    // Complete the path to the bottom-right, then bottom-left to create a closed shape
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.closeSubpath()
                    
                    // Draw the wave with blue color
                    context.stroke(path, with: .color(.blue.opacity(0.3)), lineWidth: 1)
                    context.fill(path, with: .color(.blue.opacity(0.05)))
                }
            }
        }
    }
}

