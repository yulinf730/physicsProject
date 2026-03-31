import Foundation
import StoreKit

@MainActor
final class SupportStore: ObservableObject {
    struct TipProduct: Identifiable {
        let id: String
        let fallbackTitle: String
        let fallbackDescription: String
    }

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var message: String?

    let tipProducts: [TipProduct] = [
        TipProduct(
            id: "support.drink",
            fallbackTitle: "Buy Me a Drink",
            fallbackDescription: "Support future updates for the app."
        )
    ]

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await Product.products(for: tipProducts.map(\.id))
            products = fetched.sorted { lhs, rhs in
                lhs.price < rhs.price
            }
        } catch {
            message = "Could not load support options right now."
            print("Failed to load tip products:", error.localizedDescription)
        }
    }

    func product(for tipProduct: TipProduct) -> Product? {
        products.first(where: { $0.id == tipProduct.id })
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                message = "Thank you for your support."
            case .userCancelled:
                break
            case .pending:
                message = "Your purchase is pending approval."
            @unknown default:
                message = "Something unexpected happened during purchase."
            }
        } catch {
            message = "Purchase failed. Please try again."
            print("Purchase failed:", error.localizedDescription)
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
