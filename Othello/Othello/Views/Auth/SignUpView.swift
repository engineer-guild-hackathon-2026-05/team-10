import SwiftUI

struct SignUpView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""

    private var passwordMismatch: Bool {
        !passwordConfirm.isEmpty && password != passwordConfirm
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !passwordMismatch && !authVM.isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HowTuneDesign.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("アカウント作成")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("メールアドレスで登録")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 16) {
                        signUpTextField(
                            placeholder: "メールアドレス",
                            icon: "envelope",
                            text: $email,
                            isSecure: false
                        )
                        signUpTextField(
                            placeholder: "パスワード（6文字以上）",
                            icon: "lock",
                            text: $password,
                            isSecure: true
                        )
                        signUpTextField(
                            placeholder: "パスワード確認",
                            icon: "lock.fill",
                            text: $passwordConfirm,
                            isSecure: true
                        )

                        if passwordMismatch {
                            Text("パスワードが一致しません")
                                .font(.caption)
                                .foregroundStyle(HowTuneDesign.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        if let error = authVM.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(HowTuneDesign.accent)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 24)

                    primaryButton(
                        label: "アカウントを作成",
                        icon: "person.badge.plus",
                        isLoading: authVM.isLoading
                    ) {
                        Task { await authVM.signUp(email: email, password: password) }
                    }
                    .padding(.horizontal, 24)
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1.0 : 0.5)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(HowTuneDesign.accent)
                }
            }
            .onChange(of: authVM.isLoggedIn) { _, isLoggedIn in
                if isLoggedIn { dismiss() }
            }
        }
    }

    private func signUpTextField(
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
