import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    heroSection
                    featuresSection
                    plansSection
                    ctaButton
                    footerSection
                }
                .padding(24)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color.indigo.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                selectedPlan = subscriptionManager.yearlyProduct
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            // Blurred template preview placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 140)

                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(.indigo)
            }
            .blur(radius: 2)
            .overlay {
                Image(systemName: "lock.open.fill")
                    .font(.title)
                    .foregroundStyle(.indigo)
            }

            Text("Unlock Your Full\nDashboard")
                .font(.title.bold())
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "rectangle.stack", text: "All templates & panels")
            featureRow(icon: "infinity", text: "Unlimited exports")
            featureRow(icon: "paintbrush", text: "Premium gradients & photo backgrounds")
            featureRow(icon: "bolt.fill", text: "Advanced Shortcuts (custom template & date)")
            featureRow(icon: "plus.circle", text: "Add custom panels")
        }
        .padding(.horizontal, 8)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.subheadline.bold())
                .foregroundStyle(.indigo)
                .frame(width: 24)

            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(text)
                .font(.body)
        }
    }

    // MARK: - Plans

    private var plansSection: some View {
        VStack(spacing: 12) {
            if let monthly = subscriptionManager.monthlyProduct {
                planCard(
                    product: monthly,
                    title: "Monthly",
                    subtitle: monthly.displayPrice + "/month",
                    badge: nil
                )
            }

            if let yearly = subscriptionManager.yearlyProduct {
                planCard(
                    product: yearly,
                    title: "Yearly",
                    subtitle: yearly.displayPrice + "/year",
                    badge: "SAVE 44%"
                )
            }

            if let lifetime = subscriptionManager.lifetimeProduct {
                planCard(
                    product: lifetime,
                    title: "Lifetime",
                    subtitle: lifetime.displayPrice + " once",
                    badge: "BEST VALUE"
                )
            }

            if subscriptionManager.products.isEmpty && !subscriptionManager.isLoading {
                Text("Unable to load subscription options.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Retry") {
                    Task { await subscriptionManager.loadProducts() }
                }
                .font(.caption.bold())
            }

            if subscriptionManager.isLoading {
                ProgressView()
                    .padding()
            }
        }
    }

    private func planCard(
        product: Product,
        title: String,
        subtitle: String,
        badge: String?
    ) -> some View {
        let isSelected = selectedPlan?.id == product.id

        return Button {
            selectedPlan = product
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)

                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.indigo)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if product.id == SubscriptionManager.yearlyProductID,
                       let sub = product.subscription,
                       let introOffer = sub.introductoryOffer,
                       introOffer.paymentMode == .freeTrial {
                        Text("\(introOffer.period.value)-\(introOffer.period.unit == .day ? "day" : "week") free trial")
                            .font(.caption)
                            .foregroundStyle(.indigo)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .indigo : .secondary)
                    .font(.title3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) plan, \(subtitle)\(badge.map { ", \($0)" } ?? "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(ctaButtonTitle)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .disabled(selectedPlan == nil || isPurchasing)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Button("Restore Purchases") {
                Task { await subscriptionManager.restorePurchases() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://lockscreenstudio.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://lockscreenstudio.app/privacy")!)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)

            Text("Payment is charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage subscriptions in Settings > Apple ID > Subscriptions.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    private var ctaButtonTitle: String {
        guard let plan = selectedPlan else { return "Subscribe" }

        if plan.id == SubscriptionManager.lifetimeProductID {
            return "Buy Once"
        }

        if plan.id == SubscriptionManager.yearlyProductID,
           let sub = plan.subscription,
           let intro = sub.introductoryOffer,
           intro.paymentMode == .freeTrial {
            return "Start Free Trial"
        }

        return "Subscribe"
    }

    // MARK: - Purchase

    private func purchase() async {
        guard let product = selectedPlan else { return }
        isPurchasing = true

        do {
            let success = try await subscriptionManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
