// ZenerGame.swift
// Game engine for the Zener card guessing game

import SwiftUI
import Combine

@MainActor
final class ZenerGame: ObservableObject {
    @Published private(set) var rounds: [ZenerRound] = []
    @Published private(set) var currentIndex: Int = 0

    // F5: Streak tracking
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var streakJustBroken: Bool = false

    var isComplete: Bool { currentIndex >= rounds.count }
    var progress: Double {
        rounds.isEmpty ? 0 : Double(currentIndex) / Double(rounds.count)
    }
    var score: Int { rounds.filter { $0.isCorrect }.count }
    var roundCount: Int { rounds.count }

    init(numberOfRounds: Int = 25) {
        startNewGame(numberOfRounds: numberOfRounds)
    }

    func startNewGame(numberOfRounds: Int = 25) {
        let symbols = ZenerSymbol.allCases
        rounds = (0..<numberOfRounds).map { _ in
            ZenerRound(card: ZenerCard(symbol: symbols.randomElement()!))
        }
        currentIndex = 0
        currentStreak = 0
        bestStreak = 0
        streakJustBroken = false
    }

    /// Make a guess for the current round.
    /// Returns true if correct, false if incorrect, nil if game is already complete.
    @discardableResult
    func makeGuess(_ symbol: ZenerSymbol) -> Bool? {
        guard !isComplete else { return nil }
        rounds[currentIndex].guess = symbol
        let correct = rounds[currentIndex].isCorrect

        // F5: Update streak
        if correct {
            currentStreak += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
            streakJustBroken = false
        } else {
            if currentStreak > 0 {
                streakJustBroken = true
            }
            currentStreak = 0
        }

        currentIndex += 1
        return correct
    }

    func currentRound() -> ZenerRound? {
        guard !isComplete else { return nil }
        return rounds[currentIndex]
    }

    // F5: Reset the streak-broken indicator after its animation completes
    func clearStreakBroken() {
        streakJustBroken = false
    }
}
