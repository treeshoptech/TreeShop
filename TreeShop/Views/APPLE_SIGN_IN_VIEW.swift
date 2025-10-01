import SwiftUI
import AuthenticationServices

struct APPLE_SIGN_IN_VIEW: View {
    @Environment(AuthService.self) private var authService

    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            APP_THEME.BG_PRIMARY.ignoresSafeArea()

            VStack(spacing: APP_THEME.SPACING_XL) {
                Spacer()

                // Logo and title
                VStack(spacing: APP_THEME.SPACING_LG) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 80))
                        .foregroundColor(APP_THEME.PRIMARY)

                    Text("TreeShop")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text("Map-First Business Operations")
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                // Sign in with Apple button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleSignInWithApple(result: result)
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(APP_THEME.RADIUS_MD)
                .padding(.horizontal, APP_THEME.SPACING_XL)

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.ERROR)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, APP_THEME.SPACING_XL)
                }

                if isLoading {
                    ProgressView()
                        .tint(APP_THEME.PRIMARY)
                }

                Spacer()
            }
            .padding(APP_THEME.SPACING_XL)
        }
        .preferredColorScheme(.dark)
    }

    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true
            errorMessage = nil

            Task {
                do {
                    try await authService.handleSignInWithApple(authorization: authorization)
                    isLoading = false
                } catch {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
