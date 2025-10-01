//
//  LoginView.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignUp = false

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("TreeShop")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Map-First Business Operations")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .padding(.top, 60)

                Spacer()

                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundStyle(.white)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .textContentType(.password)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundStyle(.white)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await login() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        showingSignUp = true
                    } label: {
                        Text("Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
        .modelContainer(for: User.self, inMemory: true)
}
