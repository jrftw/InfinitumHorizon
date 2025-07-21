import SwiftUI
import SwiftData
import UIKit

// MARK: - Authentication Protocol
@MainActor
protocol AuthenticationManager: ObservableObject {
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    var isLoading: Bool { get }
    var authError: String? { get set }
    
    func login(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func register(username: String, email: String, password: String, confirmPassword: String, completion: @escaping (Result<User, Error>) -> Void)
    func logout()
}

// MARK: - Custom Alert View (Safe Alternative to UIAlertController)
struct CustomAlertView: View {
    let title: String
    let message: String
    let dismissAction: () -> Void
    let showCustomButtons: Bool
    let customButtons: (() -> AnyView)?
    
    init(title: String, message: String, dismissAction: @escaping () -> Void, showCustomButtons: Bool = false, customButtons: (() -> AnyView)? = nil) {
        self.title = title
        self.message = message
        self.dismissAction = dismissAction
        self.showCustomButtons = showCustomButtons
        self.customButtons = customButtons
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !showCustomButtons {
                        dismissAction()
                    }
                }
            
            // Alert content
            VStack(spacing: 20) {
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Buttons
                if showCustomButtons, let customButtons = customButtons {
                    customButtons()
                } else {
                    // Default OK button
                    Button("OK") {
                        dismissAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}

// MARK: - Custom SwiftUI Toggle (No UISwitch)
struct SafeToggle: View {
    @Binding var isOn: Bool
    let title: String
    
    var body: some View {
        HStack {
            // Custom toggle using only SwiftUI components
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn.toggle()
                }
            }) {
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isOn ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 51, height: 31)
                    
                    // Toggle circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 27, height: 27)
                        .shadow(radius: 2)
                        .offset(x: isOn ? 10 : -10)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .id("customToggle_\(title)")
            
            Text(title)
                .font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Authentication View
struct AuthenticationView<AuthManagerType: AuthenticationManager>: View {
    @ObservedObject var authManager: AuthManagerType
    @State private var showSignUp = false
    @State private var isLoading = false
    @State private var showErrorAlert = false
    
    // Ensure fullscreen layout
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Ensure fullscreen layout on all devices
                #if targetEnvironment(macCatalyst)
                // Force single column layout on Mac Catalyst
                #endif
                // App Icon
                Image(systemName: "infinity.circle.fill")
                    .font(.system(size: 100, weight: .medium))
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .red, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                // Title
                Text("Infinitum Horizon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Subtitle
                Text("Welcome Back")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                // Login Form
                LoginView(authManager: authManager)
                
                // Sign Up Link
                VStack(spacing: 10) {
                    Text("Don't have an account?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button("Create Account") {
                        showSignUp = true
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
            }
            .padding()
            .padding(.top, 60) // Add extra top padding to prevent icon cutoff
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .navigationBarHidden(true)
            .navigationViewStyle(StackNavigationViewStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .ignoresSafeArea(.container, edges: .all)
            // Force single column layout on all devices
            .navigationSplitViewStyle(.balanced)
            .sheet(isPresented: $showSignUp) {
                SignUpView(authManager: authManager)
            }
            .onChange(of: authManager.authError) { oldValue, newValue in
                // Only show alert if there's an error and we're not already showing one
                if newValue != nil && !showErrorAlert {
                    // Small delay to ensure proper alert presentation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showErrorAlert = true
                    }
                }
            }
            .overlay {
                if showErrorAlert {
                    CustomAlertView(
                        title: "Authentication Error",
                        message: authManager.authError ?? "An unknown error occurred",
                        dismissAction: {
                            authManager.authError = nil
                            showErrorAlert = false
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Login View
struct LoginView<AuthManagerType: AuthenticationManager>: View {
    @ObservedObject var authManager: AuthManagerType
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
            }
            
            // Remember Me - Using safe toggle
            SafeToggle(isOn: $rememberMe, title: "Remember Me")
            
            // Login Button
            Button(action: {
                authManager.login(email: email, password: password) { result in
                    switch result {
                    case .success(_):
                        // Login successful
                        break
                    case .failure(_):
                        // Error is handled by authManager.authError
                        break
                    }
                }
            }) {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty)
            
            // Forgot Password
            Button("Forgot Password?") {
                // Handle forgot password
            }
            .font(.subheadline)
            .foregroundStyle(.blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Sign Up View
struct SignUpView<AuthManagerType: AuthenticationManager>: View {
    @ObservedObject var authManager: AuthManagerType
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(.blue)
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join Infinitum Horizon")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                // Form
                VStack(spacing: 16) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                        TextField("Choose a username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.username)
                            .autocapitalization(.none)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        SecureField("Create a password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                    }
                    
                    // Confirm Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.headline)
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                    }
                    
                    // Terms Agreement - Using safe toggle
                    SafeToggle(isOn: $agreeToTerms, title: "I agree to the Terms of Service and Privacy Policy")
                    
                    // Sign Up Button
                    Button(action: {
                        authManager.register(
                            username: username,
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword
                        ) { result in
                            switch result {
                            case .success(_):
                                // Small delay to ensure user is properly logged in before dismissing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    dismiss()
                                }
                            case .failure(_):
                                // Error is handled by authManager.authError
                                break
                            }
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authManager.isLoading || !isFormValid)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Spacer()
            }
            .padding()
            .padding(.top, 20) // Add top padding to prevent header cutoff
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .onChange(of: authManager.authError) { oldValue, newValue in
                // Only show alert if there's an error and we're not already showing one
                if newValue != nil && !showErrorAlert {
                    // Small delay to ensure proper alert presentation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showErrorAlert = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showErrorAlert {
                    CustomAlertView(
                        title: "Authentication Error",
                        message: authManager.authError ?? "An unknown error occurred",
                        dismissAction: {
                            authManager.authError = nil
                            showErrorAlert = false
                        }
                    )
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        agreeToTerms
    }
}

// MARK: - Cool Loading Screen
struct CoolLoadingScreen: View {
    @State private var isAnimating = false
    @State private var progress = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.blue.opacity(0.8), .purple.opacity(0.8), .cyan.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated logo
                Image(systemName: "infinity.circle.fill")
                    .font(.system(size: 120, weight: .medium))
                    .foregroundStyle(.linearGradient(
                        colors: [.orange, .red, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                
                // App name
                Text("Infinitum Horizon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                // Progress bar
                VStack(spacing: 10) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(height: 8)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: 200)
            }
        }
        .onAppear {
            isAnimating = true
            animateProgress()
        }
    }
    
    private func animateProgress() {
        withAnimation(.easeInOut(duration: 3)) {
            progress = 1.0
        }
    }
}

// MARK: - Floating Particle
struct FloatingParticle: View {
    let index: Int
    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        .orange.opacity(0.6),
                        .red.opacity(0.4),
                        .yellow.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: CGFloat.random(in: 2...6), height: CGFloat.random(in: 2...6))
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                startFloating()
            }
    }
    
    private func startFloating() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Random starting position
        offset = CGSize(
            width: CGFloat.random(in: -screenWidth/2...screenWidth/2),
            height: CGFloat.random(in: -screenHeight/2...screenHeight/2)
        )
        
        // Fade in
        withAnimation(.easeIn(duration: 1.0).delay(Double(index) * 0.1)) {
            opacity = Double.random(in: 0.3...0.8)
        }
        
        // Start floating animation
        withAnimation(
            .easeInOut(duration: Double.random(in: 8...15))
            .repeatForever(autoreverses: true)
        ) {
            offset = CGSize(
                width: CGFloat.random(in: -screenWidth/2...screenWidth/2),
                height: CGFloat.random(in: -screenHeight/2...screenHeight/2)
            )
        }
    }
}

// MARK: - Keychain Manager for Secure Password Storage
class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    func savePassword(_ password: String, for email: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecValueData as String: password.data(using: .utf8)!
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getPassword(for email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    func deletePassword(for email: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: email
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showResetForm = false
    @State private var resetToken = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Reset Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Enter your email to receive a password reset link")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                if !showResetForm {
                    // Email Request Form
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        Button("Send Reset Link") {
                            requestReset()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(email.isEmpty)
                    }
                    .padding(.horizontal, 20)
                } else {
                    // Reset Form
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reset Token")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            TextField("Enter reset token from email", text: $resetToken)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter new password", text: $newPassword)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textFieldStyle(.roundedBorder)
                                        .textContentType(.newPassword)
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            SecureField("Confirm new password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                        }
                        
                        Button("Reset Password") {
                            resetPassword()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canReset ? .blue : .gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(!canReset)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var canReset: Bool {
        !resetToken.isEmpty && 
        !newPassword.isEmpty && 
        !confirmPassword.isEmpty && 
        newPassword == confirmPassword
    }
    
    private func requestReset() {
        authManager.requestPasswordReset(email: email) { success in
            if success {
                showResetForm = true
            }
        }
    }
    
    private func resetPassword() {
        authManager.resetPassword(token: resetToken, newPassword: newPassword) { success in
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Email Verification View
struct EmailVerificationView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var verificationToken = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Verify Your Email")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Please check your email and enter the verification code")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Verification Form
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Enter verification code", text: $verificationToken)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    Button("Verify Email") {
                        verifyEmail()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(verificationToken.isEmpty)
                    
                    Button("Resend Code") {
                        resendCode()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Email Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func verifyEmail() {
        authManager.verifyEmail(token: verificationToken) { success in
            if success {
                dismiss()
            }
        }
    }
    
    private func resendCode() {
        authManager.resendVerificationEmail { success in
            // Handle resend result
        }
    }
}

// MARK: - Main App View with Account Management
struct MainAppView: View {
    @ObservedObject var authManager: AuthManager
    @State private var showAccountSettings = false
    @State private var showDeleteAccount = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Welcome Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Welcome, \(authManager.currentUser?.username ?? "User")!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("You're successfully signed in to Infinitum Horizon")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Account Status
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        Text("Account Information")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 16) {
                        AccountInfoRow(
                            icon: "person.circle.fill",
                            label: "Username:",
                            value: authManager.currentUser?.username ?? "Unknown"
                        )
                        
                        AccountInfoRow(
                            icon: "envelope.circle.fill",
                            label: "Email:",
                            value: authManager.currentUser?.email ?? "Unknown"
                        )
                        
                        AccountInfoRow(
                            icon: "checkmark.shield.circle.fill",
                            label: "Email Verified:",
                            value: authManager.currentUser?.isEmailVerified == true ? "Yes" : "No"
                        )
                        
                        AccountInfoRow(
                            icon: "crown.circle.fill",
                            label: "Premium Status:",
                            value: authManager.currentUser?.subscriptionStatus ?? "Free"
                        )
                        
                        AccountInfoRow(
                            icon: "calendar.circle.fill",
                            label: "Member Since:",
                            value: authManager.currentUser?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
                        )
                    }
                }
                .padding(20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Account Actions
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "gear.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        
                        Text("Account Actions")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 16) {
                        AccountActionButton(
                            icon: "person.circle.fill",
                            title: "Account Settings",
                            subtitle: "Manage your profile and preferences",
                            color: .blue
                        ) {
                            showAccountSettings = true
                        }
                        
                        AccountActionButton(
                            icon: "arrow.right.square.fill",
                            title: "Log Out",
                            subtitle: "Sign out of your account",
                            color: .orange
                        ) {
                            logout()
                        }
                        
                        AccountActionButton(
                            icon: "trash.circle.fill",
                            title: "Delete Account",
                            subtitle: "Permanently delete your account and data",
                            color: .red
                        ) {
                            showDeleteAccount = true
                        }
                    }
                }
                .padding(20)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .background(.ultraThinMaterial)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView(authManager: authManager)
        }
        .overlay {
            if showDeleteAccount {
                CustomAlertView(
                    title: "Delete Account",
                    message: "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.",
                    dismissAction: {
                        showDeleteAccount = false
                    },
                    showCustomButtons: true,
                    customButtons: {
                        AnyView(
                            HStack(spacing: 16) {
                                Button("Cancel") {
                                    showDeleteAccount = false
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Delete") {
                                    deleteAccount()
                                    showDeleteAccount = false
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                        )
                    }
                )
            }
        }
    }
    
    private func logout() {
        // Clear saved credentials
        if let email = UserDefaults.standard.string(forKey: "savedEmail") {
            _ = KeychainManager.shared.deletePassword(for: email)
        }
        UserDefaults.standard.removeObject(forKey: "savedEmail")
        
        // Logout from auth manager
        authManager.logout()
    }
    
    private func deleteAccount() {
        // Clear saved credentials
        if let email = UserDefaults.standard.string(forKey: "savedEmail") {
            _ = KeychainManager.shared.deletePassword(for: email)
        }
        UserDefaults.standard.removeObject(forKey: "savedEmail")
        
        // Delete account from auth manager
        authManager.deleteAccount { success in
            if success {
                authManager.logout()
            }
        }
    }
}

// MARK: - Account Info Row
struct AccountInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(label)
                .font(.body)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Account Action Button
struct AccountActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Account Settings View
struct AccountSettingsView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var bio = ""
    @State private var showChangePassword = false
    @State private var showEmailVerification = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Section
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            Text("Profile Settings")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("Enter display name", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bio")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                TextField("Tell us about yourself", text: $bio, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Security Section
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "lock.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                            
                            Text("Security")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 16) {
                            SettingsActionButton(
                                icon: "key.circle.fill",
                                title: "Change Password",
                                subtitle: "Update your account password",
                                color: .blue
                            ) {
                                showChangePassword = true
                            }
                            
                            if authManager.currentUser?.isEmailVerified != true {
                                SettingsActionButton(
                                    icon: "envelope.circle.fill",
                                    title: "Verify Email",
                                    subtitle: "Verify your email address",
                                    color: .orange
                                ) {
                                    showEmailVerification = true
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Save Button
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .fontWeight(.semibold)
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            loadUserData()
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView(authManager: authManager)
        }
        .sheet(isPresented: $showEmailVerification) {
            EmailVerificationView(authManager: authManager)
        }
    }
    
    private func loadUserData() {
        displayName = authManager.currentUser?.displayName ?? ""
        bio = authManager.currentUser?.bio ?? ""
    }
    
    private func saveChanges() {
        // Save user data
        authManager.currentUser?.displayName = displayName
        authManager.currentUser?.bio = bio
        authManager.currentUser?.updatedAt = Date()
        
        // In a real app, you would save this to the database
        // Changes saved
        dismiss()
    }
}

// MARK: - Settings Action Button
struct SettingsActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Change Password View
struct ChangePasswordView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Change Password")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Update your account password")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Password Form
                VStack(spacing: 24) {
                    // Current Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Password")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            if showCurrentPassword {
                                TextField("Enter current password", text: $currentPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                            } else {
                                SecureField("Enter current password", text: $currentPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                            }
                            
                            Button(action: {
                                showCurrentPassword.toggle()
                            }) {
                                Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            if showNewPassword {
                                TextField("Enter new password", text: $newPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Enter new password", text: $newPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.newPassword)
                            }
                            
                            Button(action: {
                                showNewPassword.toggle()
                            }) {
                                Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text("At least 8 characters with letters and numbers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Confirm New Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm New Password")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        SecureField("Confirm new password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                    }
                    
                    // Update Button
                    Button("Update Password") {
                        updatePassword()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canUpdate ? .blue : .gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .fontWeight(.semibold)
                    .disabled(!canUpdate)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var canUpdate: Bool {
        !currentPassword.isEmpty && 
        !newPassword.isEmpty && 
        !confirmPassword.isEmpty && 
        newPassword == confirmPassword &&
        User.isValidPassword(newPassword)
    }
    
    private func updatePassword() {
        // In a real app, you would verify the current password and update
        // Password updated
        dismiss()
    }
} 