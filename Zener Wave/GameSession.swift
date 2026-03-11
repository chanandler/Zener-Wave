// GameSession.swift
// SwiftData model for persisting completed game sessions

import Foundation
import SwiftData

@Model
final class GameSession {
    var id: UUID
    var date: Date
    var roundCount: Int
    var score: Int

    // Per-symbol results stored as parallel Int arrays.
    // Index maps to ZenerSymbol.allCases order: circle, cross, waves, square, star
    var symbolAppearances: [Int]
    var symbolCorrect: [Int]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        roundCount: Int,
        score: Int,
        symbolAppearances: [Int],
        symbolCorrect: [Int]
    ) {
        self.id = id
        self.date = date
        self.roundCount = roundCount
        self.score = score
        self.symbolAppearances = symbolAppearances
        self.symbolCorrect = symbolCorrect
    }
}

// MARK: - Factory

extension GameSession {
    /// Create a GameSession from a completed set of rounds
    static func from(rounds: [ZenerRound]) -> GameSession {
        let allSymbols = ZenerSymbol.allCases
        var appearances = Array(repeating: 0, count: allSymbols.count)
        var correct = Array(repeating: 0, count: allSymbols.count)

        for round in rounds {
            if let idx = allSymbols.firstIndex(of: round.card.symbol) {
                appearances[idx] += 1
                if round.isCorrect { correct[idx] += 1 }
            }
        }

        return GameSession(
            roundCount: rounds.count,
            score: rounds.filter(\.isCorrect).count,
            symbolAppearances: appearances,
            symbolCorrect: correct
        )
    }

    var accuracyPercent: Double {
        guard roundCount > 0 else { return 0 }
        return Double(score) / Double(roundCount) * 100
    }
}
