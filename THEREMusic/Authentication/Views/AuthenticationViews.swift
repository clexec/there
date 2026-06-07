import SwiftUI

// MARK: - AuthenticationView
struct AuthenticationView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            switch viewModel.flow {
            case .landing:                              LandingAuthView(viewModel: viewModel)
            case .emailEntry:                           EmailEntryView(viewModel: viewModel)
            case .login(let email):                     LoginView(email: email, parentVM: viewModel)
            case .register(let email):                  RegisterView(email: email, parentVM: viewModel)
            case .forgotPassword(let email):            ForgotPasswordView(email: email, parentVM: viewModel)
            case .resetPassword(let email):             ResetPasswordView(email: email, parentVM: viewModel)
            }
        }
        .animation(UIConstants.Animation.medium, value: "\(viewModel.flow)")
        .preferredColorScheme(.dark)
    }
}

// MARK: - LandingAuthView
struct LandingAuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            logoSection
            Spacer()
            descriptionSection
            Spacer()
            buttonsSection
            termsSection
        }
        .padding(.horizontal, UIConstants.Spacing.xl)
        .padding(.bottom, UIConstants.Spacing.xxl)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) { logoScale = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.3))                      { contentOpacity = 1 }
        }
    }

    private var logoSection: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            ZStack {
                Circle()
                    .fill(ColorPalette.primaryGreen.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                Image(systemName: "music.note.list")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(ColorPalette.primaryGreen)
            }
            .scaleEffect(logoScale)

            Text(AppConstants.appName)
                .font(.system(size: UIConstants.FontSize.largeTitle, weight: .black))
                .foregroundStyle(ColorPalette.textPrimary)
                .opacity(contentOpacity)
        }
    }

    private var descriptionSection: some View {
        VStack(spacing: UIConstants.Spacing.sm) {
            Text(NSLocalizedString("auth_title", comment: ""))
                .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)

            Text(NSLocalizedString("auth_subtitle", comment: ""))
                .font(.system(size: UIConstants.FontSize.body))
                .foregroundStyle(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .opacity(contentOpacity)
    }

    private var buttonsSection: some View {
        VStack(spacing: UIConstants.Spacing.md) {
            AuthButtonsView(viewModel: viewModel)
        }
        .opacity(contentOpacity)
    }

    private var termsSection: some View {
        VStack(spacing: UIConstants.Spacing.xs) {
            Text(NSLocalizedString("auth_terms_intro", comment: ""))
                .font(.system(size: UIConstants.FontSize.caption))
                .foregroundStyle(ColorPalette.textTertiary)
                .multilineTextAlignment(.center)
            HStack(spacing: UIConstants.Spacing.xs) {
                Text(NSLocalizedString("terms_of_service", comment: ""))
                    .underline()
                Text("·")
                Text(NSLocalizedString("privacy_policy", comment: ""))
                    .underline()
            }
            .font(.system(size: UIConstants.FontSize.caption))
            .foregroundStyle(ColorPalette.textSecondary)
        }
        .padding(.top, UIConstants.Spacing.md)
        .opacity(contentOpacity)
    }
}

// MARK: - AuthButtonsView
struct AuthButtonsView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: UIConstants.Spacing.sm) {
            appleButton
            googleButton
            divider
            emailButton
        }
    }

    private var appleButton: some View {
        Button {
            Task { await viewModel.signInWithApple() }
        } label: {
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .semibold))
                Text(NSLocalizedString("auth_continue_apple", comment: ""))
                    .font(.system(size: UIConstants.FontSize.callout, weight: .semibold))
            }
            .foregroundStyle(ColorPalette.backgroundBlack)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule().fill(ColorPalette.textPrimary))
        }
        .scaleOnPress()
        .disabled(viewModel.isLoading)
    }

    private var googleButton: some View {
        Button {
            Task { await viewModel.signInWithGoogle() }
        } label: {
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "#EA4335"))
                Text(NSLocalizedString("auth_continue_google", comment: ""))
                    .font(.system(size: UIConstants.FontSize.callout, weight: .semibold))
                    .foregroundStyle(ColorPalette.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Capsule()
                    .fill(ColorPalette.surface3)
                    .overlay {
                        Capsule().strokeBorder(ColorPalette.glassBorder, lineWidth: 1)
                    }
            }
        }
        .scaleOnPress()
        .disabled(viewModel.isLoading)
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(ColorPalette.surface3).frame(height: 1)
            Text(NSLocalizedString("or", comment: ""))
                .font(.system(size: UIConstants.FontSize.caption))
                .foregroundStyle(ColorPalette.textTertiary)
                .padding(.horizontal, UIConstants.Spacing.sm)
            Rectangle().fill(ColorPalette.surface3).frame(height: 1)
        }
    }

    private var emailButton: some View {
        Button {
            viewModel.flow = .emailEntry
        } label: {
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: "envelope.fill")
                Text(NSLocalizedString("auth_sign_in_email", comment: ""))
                    .font(.system(size: UIConstants.FontSize.callout, weight: .semibold))
            }
            .secondaryButtonStyle()
        }
        .scaleOnPress()
        .disabled(viewModel.isLoading)
    }
}

// MARK: - EmailEntryView
struct EmailEntryView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var isFocused: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            AuthNavigationBar(title: NSLocalizedString("auth_enter_email", comment: ""), onBack: viewModel.back)
            Spacer()
            VStack(spacing: UIConstants.Spacing.xl) {
                Text(NSLocalizedString("auth_email_prompt", comment: ""))
                    .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)

                AuthTextField(
                    placeholder: NSLocalizedString("email_placeholder", comment: ""),
                    text: $email,
                    keyboardType: .emailAddress
                )

                if let error = viewModel.error {
                    ErrorLabel(message: error)
                }

                Button {
                    Task { await viewModel.proceedWithEmail(email) }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(ColorPalette.backgroundBlack)
                        } else {
                            Text(NSLocalizedString("continue", comment: ""))
                        }
                    }
                    .primaryButtonStyle(isEnabled: email.isValidEmail)
                }
                .disabled(!email.isValidEmail || viewModel.isLoading)
                .scaleOnPress()
            }
            .padding(.horizontal, UIConstants.Spacing.xl)
            Spacer()
        }
        .background(ColorPalette.backgroundBlack.ignoresSafeArea())
        .onAppear { }
    }
}

// MARK: - LoginView (Email)
struct LoginView: View {
    let email: String
    @ObservedObject var parentVM: AuthViewModel
    @StateObject private var viewModel: LoginViewModel
    @State private var isPasswordFocused: Bool = false

    init(email: String, parentVM: AuthViewModel) {
        self.email = email
        self.parentVM = parentVM
        _viewModel = StateObject(wrappedValue: LoginViewModel(email: email))
    }

    var body: some View {
        VStack(spacing: 0) {
            AuthNavigationBar(title: NSLocalizedString("auth_login", comment: ""), onBack: parentVM.back)
            Spacer()
            VStack(spacing: UIConstants.Spacing.xl) {
                VStack(spacing: UIConstants.Spacing.xs) {
                    Text(NSLocalizedString("auth_welcome_back", comment: ""))
                        .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                    Text(email)
                        .font(.system(size: UIConstants.FontSize.subheadline))
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                VStack(spacing: UIConstants.Spacing.md) {
                    AuthSecureField(
                        placeholder: NSLocalizedString("password_placeholder", comment: ""),
                        text: $viewModel.password,
                        isVisible: $viewModel.isPasswordVisible
                    )

                    HStack {
                        Spacer()
                        Button(NSLocalizedString("forgot_password", comment: "")) {
                            parentVM.navigateToForgotPassword(email: email)
                        }
                        .font(.system(size: UIConstants.FontSize.footnote))
                        .foregroundStyle(ColorPalette.primaryGreen)
                    }
                }

                if let error = viewModel.error {
                    ErrorLabel(message: error)
                }

                Button {
                    Task { await viewModel.login() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(ColorPalette.backgroundBlack)
                        } else {
                            Text(NSLocalizedString("auth_login_button", comment: ""))
                        }
                    }
                    .primaryButtonStyle(isEnabled: viewModel.canLogin)
                }
                .disabled(!viewModel.canLogin || viewModel.isLoading)
                .scaleOnPress()
            }
            .padding(.horizontal, UIConstants.Spacing.xl)
            Spacer()
        }
        .background(ColorPalette.backgroundBlack.ignoresSafeArea())
        .onAppear { }
    }
}

// MARK: - RegisterView
struct RegisterView: View {
    let email: String
    @ObservedObject var parentVM: AuthViewModel
    @StateObject private var viewModel: RegisterViewModel
    @State private var focusedField: RegisterField? = nil

    enum RegisterField { case name, password, confirm }

    init(email: String, parentVM: AuthViewModel) {
        self.email = email
        self.parentVM = parentVM
        _viewModel = StateObject(wrappedValue: RegisterViewModel(email: email))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthNavigationBar(title: NSLocalizedString("auth_create_account", comment: ""), onBack: parentVM.back)
                VStack(spacing: UIConstants.Spacing.xl) {
                    Text(NSLocalizedString("auth_create_account_title", comment: ""))
                        .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                        .padding(.top, UIConstants.Spacing.xl)

                    VStack(spacing: UIConstants.Spacing.md) {
                        AuthTextField(
                            placeholder: NSLocalizedString("name_placeholder", comment: ""),
                            text: $viewModel.displayName,
                            keyboardType: .default
                        )

                        AuthSecureField(
                            placeholder: NSLocalizedString("password_placeholder", comment: ""),
                            text: $viewModel.password,
                            isVisible: $viewModel.isPasswordVisible
                        )

                        PasswordStrengthView(strength: viewModel.passwordStrength)

                        AuthSecureField(
                            placeholder: NSLocalizedString("confirm_password_placeholder", comment: ""),
                            text: $viewModel.confirmPassword,
                            isVisible: $viewModel.isConfirmVisible
                        )

                        if !viewModel.confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(viewModel.passwordsMatch ? ColorPalette.primaryGreen : ColorPalette.errorRed)
                                Text(viewModel.passwordsMatch ? NSLocalizedString("passwords_match", comment: "") : NSLocalizedString("passwords_no_match", comment: ""))
                                    .font(.system(size: UIConstants.FontSize.caption))
                                    .foregroundStyle(viewModel.passwordsMatch ? ColorPalette.primaryGreen : ColorPalette.errorRed)
                                Spacer()
                            }
                        }
                    }

                    TermsToggleView(accepted: $viewModel.termsAccepted)

                    if let error = viewModel.error {
                        ErrorLabel(message: error)
                    }

                    Button {
                        Task { await viewModel.register() }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(ColorPalette.backgroundBlack)
                            } else {
                                Text(NSLocalizedString("auth_create_account_button", comment: ""))
                            }
                        }
                        .primaryButtonStyle(isEnabled: viewModel.canRegister)
                    }
                    .disabled(!viewModel.canRegister || viewModel.isLoading)
                    .scaleOnPress()
                    .padding(.bottom, UIConstants.Spacing.xxxl)
                }
                .padding(.horizontal, UIConstants.Spacing.xl)
            }
        }
        .background(ColorPalette.backgroundBlack.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - ForgotPasswordView
struct ForgotPasswordView: View {
    let email: String
    @ObservedObject var parentVM: AuthViewModel
    @StateObject private var viewModel: ForgotPasswordViewModel

    init(email: String, parentVM: AuthViewModel) {
        self.email = email
        self.parentVM = parentVM
        _viewModel = StateObject(wrappedValue: ForgotPasswordViewModel(email: email))
    }

    var body: some View {
        VStack(spacing: 0) {
            AuthNavigationBar(title: NSLocalizedString("forgot_password", comment: ""), onBack: parentVM.back)
            Spacer()
            VStack(spacing: UIConstants.Spacing.xl) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 56))
                    .foregroundStyle(ColorPalette.primaryGreen)

                VStack(spacing: UIConstants.Spacing.sm) {
                    Text(NSLocalizedString("forgot_password_title", comment: ""))
                        .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                    Text(NSLocalizedString("forgot_password_subtitle", comment: ""))
                        .font(.system(size: UIConstants.FontSize.body))
                        .foregroundStyle(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if !viewModel.codeSent {
                    VStack(spacing: UIConstants.Spacing.md) {
                        AuthTextField(
                            placeholder: NSLocalizedString("email_placeholder", comment: ""),
                            text: $viewModel.email,
                            keyboardType: .emailAddress,
                        )
                        if let error = viewModel.error { ErrorLabel(message: error) }
                        if let msg = viewModel.successMessage { SuccessLabel(message: msg) }
                        Button { Task { await viewModel.sendResetCode() } } label: {
                            Group {
                                if viewModel.isLoading { ProgressView().tint(ColorPalette.backgroundBlack) }
                                else { Text(NSLocalizedString("send_reset_code", comment: "")) }
                            }
                            .primaryButtonStyle()
                        }
                        .disabled(!viewModel.email.isValidEmail || viewModel.isLoading)
                        .scaleOnPress()
                    }
                }
            }
            .padding(.horizontal, UIConstants.Spacing.xl)
            Spacer()
        }
        .background(ColorPalette.backgroundBlack.ignoresSafeArea())
    }
}

// MARK: - ResetPasswordView
struct ResetPasswordView: View {
    let email: String
    @ObservedObject var parentVM: AuthViewModel
    @StateObject private var viewModel: ForgotPasswordViewModel

    init(email: String, parentVM: AuthViewModel) {
        self.email = email
        self.parentVM = parentVM
        _viewModel = StateObject(wrappedValue: ForgotPasswordViewModel(email: email))
    }

    var body: some View {
        VStack(spacing: 0) {
            AuthNavigationBar(title: NSLocalizedString("reset_password", comment: ""), onBack: parentVM.back)
            ScrollView {
                VStack(spacing: UIConstants.Spacing.xl) {
                    Text(NSLocalizedString("reset_password_title", comment: ""))
                        .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                        .padding(.top, UIConstants.Spacing.xl)

                    VStack(spacing: UIConstants.Spacing.md) {
                        AuthTextField(
                            placeholder: NSLocalizedString("reset_code_placeholder", comment: ""),
                            text: $viewModel.code,
                            keyboardType: .numberPad,
                        )
                        AuthSecureField(
                            placeholder: NSLocalizedString("new_password_placeholder", comment: ""),
                            text: $viewModel.newPassword,
                            isVisible: $viewModel.isPasswordVisible,
                        )
                        PasswordStrengthView(strength: viewModel.passwordStrength)
                        AuthSecureField(
                            placeholder: NSLocalizedString("confirm_password_placeholder", comment: ""),
                            text: $viewModel.confirmPassword,
                            isVisible: .constant(false),
                        )
                        if let error = viewModel.error   { ErrorLabel(message: error) }
                        if let msg = viewModel.successMessage { SuccessLabel(message: msg) }
                        Button { Task { await viewModel.resetPassword() } } label: {
                            Group {
                                if viewModel.isLoading { ProgressView().tint(ColorPalette.backgroundBlack) }
                                else { Text(NSLocalizedString("reset_password_button", comment: "")) }
                            }
                            .primaryButtonStyle(isEnabled: viewModel.canSubmitCode)
                        }
                        .disabled(!viewModel.canSubmitCode || viewModel.isLoading)
                        .scaleOnPress()
                    }
                    .padding(.bottom, UIConstants.Spacing.xxxl)
                }
                .padding(.horizontal, UIConstants.Spacing.xl)
            }
        }
        .background(ColorPalette.backgroundBlack.ignoresSafeArea())
    }
}

// MARK: - PasswordStrengthView
struct PasswordStrengthView: View {
    let strength: PasswordStrength

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
            HStack(spacing: UIConstants.Spacing.xs) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(segmentColor(index: i))
                        .frame(height: 4)
                        .animation(UIConstants.Animation.fast, value: strength)
                }
            }
            Text(strength.title)
                .font(.system(size: UIConstants.FontSize.caption))
                .foregroundStyle(Color(hex: strength.color))
        }
    }

    private func segmentColor(index: Int) -> Color {
        switch (strength, index) {
        case (.weak, 0):            return Color(hex: strength.color)
        case (.medium, 0), (.medium, 1): return Color(hex: strength.color)
        case (.strong, _):          return Color(hex: strength.color)
        default:                    return ColorPalette.surface3
        }
    }
}

// MARK: - Auth Shared Components
struct AuthNavigationBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .frame(width: 40, height: 40)
                    .glassCard(cornerRadius: UIConstants.Radius.md)
            }
            Spacer()
            Text(title)
                .font(.system(size: UIConstants.FontSize.callout, weight: .semibold))
                .foregroundStyle(ColorPalette.textPrimary)
            Spacer()
            Color.clear.frame(width: 40)
        }
        .padding(.horizontal, UIConstants.Spacing.xl)
        .padding(.top, UIConstants.Spacing.sm)
    }
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @FocusState private var focused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            .font(.system(size: UIConstants.FontSize.body))
            .foregroundStyle(ColorPalette.textPrimary)
            .focused($focused)
            .padding(.horizontal, UIConstants.Spacing.base)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: UIConstants.Radius.base)
                    .fill(ColorPalette.surface2)
                    .overlay {
                        RoundedRectangle(cornerRadius: UIConstants.Radius.base)
                            .strokeBorder(focused ? ColorPalette.primaryGreen : ColorPalette.glassBorder, lineWidth: 1)
                    }
            }
    }
}

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    @FocusState private var focused: Bool

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.system(size: UIConstants.FontSize.body))
            .foregroundStyle(ColorPalette.textPrimary)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focused)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(ColorPalette.textSecondary)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .frame(height: 52)
        .background {
            RoundedRectangle(cornerRadius: UIConstants.Radius.base)
                .fill(ColorPalette.surface2)
                .overlay {
                    RoundedRectangle(cornerRadius: UIConstants.Radius.base)
                        .strokeBorder(focused ? ColorPalette.primaryGreen : ColorPalette.glassBorder, lineWidth: 1)
                }
        }
    }
}

struct TermsToggleView: View {
    @Binding var accepted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: UIConstants.Spacing.sm) {
            Button {
                accepted.toggle()
            } label: {
                Image(systemName: accepted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(accepted ? ColorPalette.primaryGreen : ColorPalette.textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("terms_agreement", comment: ""))
                    .font(.system(size: UIConstants.FontSize.footnote))
                    .foregroundStyle(ColorPalette.textSecondary)
                HStack(spacing: UIConstants.Spacing.xs) {
                    Text(NSLocalizedString("terms_of_service", comment: ""))
                        .underline()
                    Text("&")
                    Text(NSLocalizedString("privacy_policy", comment: ""))
                        .underline()
                }
                .font(.system(size: UIConstants.FontSize.footnote))
                .foregroundStyle(ColorPalette.primaryGreen)
            }
        }
    }
}

struct ErrorLabel: View {
    let message: String
    var body: some View {
        HStack(spacing: UIConstants.Spacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
        }
        .font(.system(size: UIConstants.FontSize.footnote))
        .foregroundStyle(ColorPalette.errorRed)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, UIConstants.Spacing.sm)
    }
}

struct SuccessLabel: View {
    let message: String
    var body: some View {
        HStack(spacing: UIConstants.Spacing.xs) {
            Image(systemName: "checkmark.circle.fill")
            Text(message)
        }
        .font(.system(size: UIConstants.FontSize.footnote))
        .foregroundStyle(ColorPalette.primaryGreen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, UIConstants.Spacing.sm)
    }
}
