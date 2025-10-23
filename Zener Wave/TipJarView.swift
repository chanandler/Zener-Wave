import SwiftUI
import StoreKit
import Combine

@MainActor
final class TipJarModel: ObservableObject {
    @Published var product: Product?
    @Published var isLoading: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var errorMessage: String?

    let productID = "zener.tip.coffee.199"

    func load() async {
        guard product == nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [productID])
            self.product = products.first
            if self.product == nil {
                self.errorMessage = "Unable to find tip product."
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func purchase() async -> Bool {
        guard let product else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .unverified:
                    self.errorMessage = "Purchase could not be verified."
                    return false
                case .verified(let transaction):
                    await transaction.finish()
                    return true
                }
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        for await _ in Transaction.currentEntitlements {
            // Iterating current entitlements is sufficient to trigger restore in StoreKit 2
        }
    }
}

struct TipJarView: View {
    @StateObject private var model = TipJarModel()
    var onPurchased: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tip Jar")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .purchaseCompleted)) { _ in
                    toastMessage = "Thank you for the tip!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { toastMessage = nil }
                    }
                }
        }
        .task { await model.load() }
        .overlay(alignment: .bottom) {
            if let message = toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(message)
                        .font(.subheadline)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // ensure it animates when set programmatically
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {}
                }
            }
        }
        .animation(.easeInOut, value: toastMessage != nil)
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading && model.product == nil {
            ProgressView("Loading…")
        } else if let product = model.product {
            VStack(spacing: 16) {
                Text("Support the app with a small tip.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    Text(product.displayName)
                        .font(.title3).bold()
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        if await model.purchase() {
                            onPurchased?()
                            toastMessage = "Thank you for the tip!"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { toastMessage = nil }
                            }
                        }
                    }
                } label: {
                    if model.isPurchasing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Tip Now")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isPurchasing)

                Button("Restore Purchases") {
                    Task {
                        await model.restore()
                        toastMessage = "Restored purchases"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { toastMessage = nil }
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                if let message = model.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text("Tip product not available.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    TipJarView()
}
