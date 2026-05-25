import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            HowTuneDesign.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(HowTuneDesign.accentGradient)
                            .frame(width: 80, height: 80)
                            .shadow(color: HowTuneDesign.accent.opacity(0.5), radius: 20)
                        Image(systemName: "headphones")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                    Text("HowTune")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(spacing: 16) {
                    authTextField(
                        placeholder: "メールアドレス",
                        icon: "envelope",
                        text: $email,
                        isSecure: false
                    )
                    authTextField(
                        placeholder: "パスワード",
                        icon: "lock",
                        text: $password,
                        isSecure: true
                    )

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(HowTuneDesign.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                primaryButton(label: "ログイン", icon: "arrow.right", isLoading: authVM.isLoading) {
                    Task { await authVM.signIn(email: email, password: password) }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                Button {
                    authVM.errorMessage = nil
                    showSignUp = true
                } label: {
                    Text("アカウントをお持ちでない方は ")
                        .foregroundStyle(.gray)
                    + Text("新規登録")
                        .foregroundStyle(HowTuneDesign.accent)
                }
                .font(.subheadline)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSignUp) {
            SignUpView(authVM: authVM)
        }
    }

    private func authTextField(
        placeholder: String,
        icon: String,
        text: Binding<String>,
        isSecure: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.gray)
                .frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: text)
                    .foregroundStyle(.white)
            } else {
                TextField(placeholder, text: text)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(HowTuneDesign.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
