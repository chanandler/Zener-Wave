//
//  Zener_WaveApp.swift
//  Zener Wave
//
//  Created by Clint Yarwood on 19/10/2025.
//

import SwiftUI
import StoreKit

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
            for await update in Transaction.updates {
                do {
                    let transaction: Transaction = try checkVerified(update)
                    // TODO: Handle successful purchase (unlock content, notify UI, etc.)
                    await transaction.finish()
                } catch {
                    // Unverified or failed verification; handle as needed
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKitVerification", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unverified transaction"])
        case .verified(let safe):
            return safe
        }
    }
}
