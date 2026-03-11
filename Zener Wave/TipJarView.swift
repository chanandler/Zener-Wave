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
                case .verified:
                    // Fix #8: transaction.finish() is handled solely by the app-level
                    // transaction listener in Zener_WaveApp to avoid double-finishing
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

    // Fix #11: returns true if any entitlement was found, false if nothing to restore
    func restore() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        var found = false
        for await _ in Transaction.currentEntitlements {
            found = true
        }
        return found
    }
}

struct TipJarView: View {
    @StateObject private var model = TipJarModel()
    var onPurchased: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var toastMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Sheet header with title and explicit Close button
            HStack {
                Text("Tip Jar")
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            content
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
                    // Fix #10: use structured concurrency (Task.sleep) instead of DispatchQueue
                    Task { @MainActor in
                        if await model.purchase() {
                            onPurchased?()
                            toastMessage = "Thank you for the tip!"
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { toastMessage = nil }
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
                    // Fix #10: use Task.sleep instead of DispatchQueue
                    // Fix #11: show different message depending on whether anything was restored
                    Task { @MainActor in
                        let restored = await model.restore()
                        toastMessage = restored ? "Purchases restored" : "No purchases to restore"
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { toastMessage = nil }
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
