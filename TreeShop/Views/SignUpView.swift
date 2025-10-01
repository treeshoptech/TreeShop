//
//  SignUpView.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)

                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Start mapping your tree business")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        .padding(.top, 40)

                        // Sign Up Form
                        VStack(spacing: 16) {
                            TextField("Full Name", text: $name)
                                .textFieldStyle(.plain)
                                .textContentType(.name)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundStyle(.white)

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
                                .textContentType(.newPassword)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundStyle(.white)

                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.plain)
                                .textContentType(.newPassword)
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
                                Task { await signUp() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Create Account")
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !isFormValid)
                        }
                        .padding(.horizontal, 32)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.green)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }

    private func signUp() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(email: email, password: password, name: name)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    SignUpView()
        .modelContainer(for: User.self, inMemory: true)
}
