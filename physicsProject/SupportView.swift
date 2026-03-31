import SwiftUI
import StoreKit

struct SupportView: View {
    @StateObject private var store = SupportStore()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 10) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pink, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Support Me")
                        .font(.system(size: 32, weight: .bold))

                    Text("The app will stay free. If you want to support future updates, you can buy me a drink here in the app.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.top, 20)

                supportCard
                aboutCard
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.orange.opacity(0.08),
                    Color.pink.opacity(0.08),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
        .alert("Support", isPresented: Binding(
            get: { store.message != nil },
            set: { newValue in
                if !newValue {
                    store.message = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                store.message = nil
            }
        } message: {
            Text(store.message ?? "")
        }
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Ways to Support")
                .font(.headline)

            if store.isLoading && store.products.isEmpty {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Loading support options...")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(store.tipProducts) { tipProduct in
                        let product = store.product(for: tipProduct)

                        supportButton(
                            title: product?.displayName ?? tipProduct.fallbackTitle,
                            subtitle: product?.description ?? tipProduct.fallbackDescription,
                            priceText: product?.displayPrice ?? "Set in App Store Connect",
                            icon: "cup.and.saucer.fill",
                            tint: .orange,
                            isEnabled: product != nil
                        ) {
                            guard let product else { return }
                            Task {
                                await store.purchase(product)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Why Support Helps")
                .font(.headline)

            Text("Support helps me keep improving the question bank, polish the app, and add more useful study features over time.")
                .font(.body)
                .foregroundColor(.secondary)

            Text("Thank you for using the app.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func supportButton(
        title: String,
        subtitle: String,
        priceText: String,
        icon: String,
        tint: Color,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tint.opacity(0.16))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Text(priceText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isEnabled ? tint : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isEnabled ? 0.6 : 0.35))
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.7)
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
}
