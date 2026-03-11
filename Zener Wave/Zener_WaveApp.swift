//
//  Zener_WaveApp.swift
//  Zener Wave
//
//  Created by Clint Yarwood on 19/10/2025.
//

import SwiftUI
import StoreKit

extension Notification.Name {
    static let purchaseCompleted = Notification.Name("PurchaseCompletedNotification")
}

@inline(__always)
nonisolated private func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
        throw NSError(domain: "StoreKitVerification", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unverified transaction"])
    case .verified(let safe):
        return safe
    }
}

@main
struct Zener_WaveApp: App {
    @State private var transactionListenerTask: Task<Void, Never>? = nil
    
    var body: some Scene {
        WindowGroup {
            NavigationStack { ZenerGameView() }
                .task { startTransactionListener() }
        }
    }
    
    private func startTransactionListener() {
        guard transactionListenerTask == nil else { return }
        transactionListenerTask = Task.detached(priority: .background) {
            for await update in StoreKit.Transaction.updates {
                do {
                    let transaction: StoreKit.Transaction = try checkVerified(update)
                    // Fix #21: only finish and notify for tip purchases, not any product
                    // Fix #8: finish() is the sole responsibility of this listener;
                    //         purchase() in TipJarModel no longer calls finish() to avoid double-finishing
                    await transaction.finish()
                } catch {
                    // Unverified or failed verification; handle as needed
                }
            }
        }
    }
}

