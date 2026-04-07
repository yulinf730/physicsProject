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
    @Published var isPurchasing = false
    @Published var availabilityMessage: String?
    @Published var alertMessage: String?

    private var transactionUpdatesTask: Task<Void, Never>?

    let tipProducts: [TipProduct] = [
        TipProduct(
            id: "support.drink",
            fallbackTitle: "Buy Me a Drink",
            fallbackDescription: "Support future updates for the app."
        )
    ]

    init() {
        transactionUpdatesTask = Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                await self.handleTransactionUpdate(result)
            }
        }
    }

    func loadProducts() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await Product.products(for: tipProducts.map(\.id))
            products = fetched.sorted { lhs, rhs in
                lhs.price < rhs.price
            }
            availabilityMessage = products.isEmpty
                ? "The support option is not available yet. Please check again after the in-app purchase is ready."
                : nil
        } catch {
            products = []
            availabilityMessage = "Could not load the support option right now. Please try again."
            print("Failed to load tip products:", error.localizedDescription)
        }
    }

    func product(for tipProduct: TipProduct) -> Product? {
        products.first(where: { $0.id == tipProduct.id })
    }

    func purchase(_ product: Product) async {
        guard !isPurchasing else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await complete(transaction, showsThankYouMessage: true)
            case .userCancelled:
                break
            case .pending:
                alertMessage = "Your purchase is pending approval. If it completes later, the app will process it automatically."
            @unknown default:
                alertMessage = "Something unexpected happened during purchase."
            }
        } catch {
            alertMessage = "Purchase failed. Please try again."
            print("Purchase failed:", error.localizedDescription)
        }
    }

    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await complete(transaction, showsThankYouMessage: isSupportProduct(transaction.productID))
        } catch {
            print("Failed to process transaction update:", error.localizedDescription)
        }
    }

    private func complete(_ transaction: Transaction, showsThankYouMessage: Bool) async {
        await transaction.finish()

        if showsThankYouMessage {
            alertMessage = "Thank you for your support."
        }
    }

    private func isSupportProduct(_ productID: String) -> Bool {
        tipProducts.contains(where: { $0.id == productID })
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
