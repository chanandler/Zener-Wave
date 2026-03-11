//
//  Zener_WaveApp.swift
//  Zener Wave
//
//  Created by Clint Yarwood on 19/10/2025.
//

import SwiftUI
import StoreKit
import SwiftData

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

// AppDelegate owns the transaction listener task, giving it a well-defined
// lifetime that starts at launch and is cancelled on app termination via deinit.
final class AppDelegate: NSObject, UIApplicationDelegate {
    private var transactionListenerTask: Task<Void, Never>?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        transactionListenerTask = Task.detached(priority: .background) {
            for await update in StoreKit.Transaction.updates {
                do {
                    let transaction: StoreKit.Transaction = try checkVerified(update)
                    await transaction.finish()
                } catch {
                    // Unverified or failed verification; handle as needed
                }
            }
        }
        return true
    }

    deinit {
        transactionListenerTask?.cancel()
    }
}

@main
struct Zener_WaveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationStack { ZenerGameView() }
        }
        // F1: Provide SwiftData model container to all views
        .modelContainer(for: GameSession.self)
    }
}
