// ScoreInterpreter.swift
// Statistical interpretation of Zener test scores

import Foundation

struct ScoreInterpretation {
    let score: Int
    let totalRounds: Int
    let expectedByChance: Double
    let deviationFromChance: Double
    let pValue: Double
    let oddsString: String
    let headline: String
    let flavourText: String
}

enum ScoreInterpreter {
    // Probability of each guess being correct by chance (1 in 5 symbols)
    private static let chanceP: Double = 0.2

    static func interpret(score: Int, totalRounds: Int) -> ScoreInterpretation {
        let expected = Double(totalRounds) * chanceP
        let deviation = Double(score) - expected

        // P(X >= score) using binomial survival function
        let pValue = binomialSurvival(k: score, n: totalRounds, p: chanceP)
        let oddsString: String
        if pValue <= 0 {
            oddsString = "astronomically rare"
        } else if pValue >= 1 {
            oddsString = "very common"
        } else {
            let oneIn = Int(round(1.0 / pValue))
            oddsString = "1 in \(max(1, oneIn))"
        }

        let ratio = totalRounds > 0 ? Double(score) / Double(totalRounds) : 0

        let headline: String
        let flavour: String

        switch ratio {
        case ..<0.12:
            headline = "Well Below Chance"
            flavour = "Perhaps the cards are actively avoiding you."
        case 0.12..<0.18:
            headline = "Below Chance"
            flavour = "Your psychic sensitivity appears to be... dormant."
        case 0.18..<0.24:
            headline = "Right at Chance"
            flavour = "Statistically indistinguishable from random guessing."
        case 0.24..<0.32:
            headline = "Slightly Above Chance"
            flavour = "A glimmer of something? Or just a lucky run."
        case 0.32..<0.44:
            headline = "Above Chance"
            flavour = "Interesting. The odds say this shouldn't happen often."
        case 0.44..<0.60:
            headline = "Well Above Chance"
            flavour = "Either you're quite lucky, or something unusual is going on."
        default:
            headline = "Remarkably High"
            flavour = "Rhine would have written a paper about you."
        }

        return ScoreInterpretation(
            score: score,
            totalRounds: totalRounds,
            expectedByChance: expected,
            deviationFromChance: deviation,
            pValue: pValue,
            oddsString: oddsString,
            headline: headline,
            flavourText: flavour
        )
    }

    // MARK: - Binomial Math

    /// P(X >= k) for Binomial(n, p), using log-space arithmetic for stability
    private static func binomialSurvival(k: Int, n: Int, p: Double) -> Double {
        guard k > 0 else { return 1.0 }
        guard k <= n else { return 0.0 }
        var sum = 0.0
        for i in k...n {
            let logProb = logBinomialCoeff(n: n, k: i)
                + Double(i) * log(p)
                + Double(n - i) * log(1.0 - p)
            sum += exp(logProb)
        }
        return min(1.0, max(0.0, sum))
    }

    /// log C(n, k) using lgamma for numerical stability
    private static func logBinomialCoeff(n: Int, k: Int) -> Double {
        lgamma(Double(n + 1)) - lgamma(Double(k + 1)) - lgamma(Double(n - k + 1))
    }
}
