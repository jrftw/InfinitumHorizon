import SwiftUI

// MARK: - View Extensions
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}



// MARK: - Premium Upgrade View
struct PremiumUpgradeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.circle.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(.linearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))

                        
                        Text("Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text("Unlock all features and remove ads")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Premium Features
                    VStack(spacing: 24) {
                        HStack {
                            Image(systemName: "sparkles.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.linearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            Text("Premium Features")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            PremiumFeatureCard(icon: "1.circle.fill", title: "All 10 Screens", color: .blue)
                            PremiumFeatureCard(icon: "xmark.circle.fill", title: "No Ads", color: .green)
                            PremiumFeatureCard(icon: "cloud.circle.fill", title: "Cloud Sync", color: .cyan)
                            PremiumFeatureCard(icon: "gear.circle.fill", title: "Advanced Settings", color: .orange)
                            PremiumFeatureCard(icon: "chart.circle.fill", title: "Analytics", color: .purple)
                            PremiumFeatureCard(icon: "person.3.circle.fill", title: "Team Features", color: .pink)
                        }
                    }
                    
                    // Pricing
                    VStack(spacing: 20) {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.linearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            
                            Text("Pricing")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 16) {
                            PricingOption(
                                title: "Monthly",
                                price: "$4.99",
                                period: "per month",
                                isPopular: false
                            ) {
                                viewModel.upgradeToPremium(plan: "monthly")
                                dismiss()
                            }
                            
                            PricingOption(
                                title: "Yearly",
                                price: "$39.99",
                                period: "per year",
                                isPopular: true,
                                savings: "Save 33%"
                            ) {
                                viewModel.upgradeToPremium(plan: "yearly")
                                dismiss()
                            }
                        }
                    }
                    
                    // Terms
                    VStack(spacing: 16) {
                        Text("Terms & Conditions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Premium subscription will automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage your subscriptions in your device's account settings.")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Premium Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Promo Code View
struct PromoCodeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var promoCode = ""
    @State private var isValidating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "ticket.circle.fill")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        
                    
                    Text("Enter Promo Code")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Redeem your promotional code for premium access")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Promo Code Input
                VStack(spacing: 24) {
                    HStack {
                        Image(systemName: "ticket.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        
                        Text("Promo Code")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 16) {
                        TextField("Enter your promo code", text: $promoCode)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                            .fontWeight(.medium)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        
                        Button("Redeem Code") {
                            isValidating = true
                            viewModel.redeemPromoCode(promoCode) { success in
                                isValidating = false
                                if success {
                                    dismiss()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .fontWeight(.medium)
                        .disabled(promoCode.isEmpty || isValidating)
                        
                        if isValidating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Validating code...")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Available Promo Codes
                VStack(spacing: 20) {
                    HStack {
                        Image(systemName: "gift.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        
                        Text("Available Codes")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    VStack(spacing: 12) {
                        PromoCodeExample(code: "WELCOME50", description: "50% off first month")
                        PromoCodeExample(code: "FREETRIAL", description: "7-day free trial")
                        PromoCodeExample(code: "LAUNCH25", description: "25% off yearly plan")
                    }
                }
                
                Spacer()
                
                // Close Button
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial)
            .navigationTitle("Promo Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Helper Views
struct PremiumFeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PricingOption: View {
    let title: String
    let price: String
    let period: String
    let isPopular: Bool
    var savings: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if isPopular {
                    HStack {
                        Spacer()
                        Text("MOST POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(.orange)
                            .clipShape(Capsule())
                    }
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(price)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        Text(period)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let savings = savings {
                        Text(savings)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(isPopular ? .regularMaterial : .ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPopular ? .orange : .clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PromoCodeExample: View {
    let code: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(code)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "gift.fill")
                .foregroundStyle(.green)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
} 