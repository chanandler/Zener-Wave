// Models.swift
// Core model types for the Zener card guessing game

import Foundation

// MARK: - Symbol

enum ZenerSymbol: String, CaseIterable, Identifiable, Equatable, Codable {
    case circle = "○"
    case cross = "✕"
    case waves = "≈"
    case square = "▢"
    case star = "★"

    var id: String { rawValue }
    var name: String {
        switch self {
        case .circle: return "Circle"
        case .cross: return "Cross"
        case .waves: return "Waves"
        case .square: return "Square"
        case .star: return "Star"
        }
    }
}

// MARK: - Card & Round

struct ZenerCard: Identifiable, Equatable {
    let id = UUID()
    let symbol: ZenerSymbol
}

struct ZenerRound: Identifiable, Equatable {
    let id = UUID()
    let card: ZenerCard
    var guess: ZenerSymbol?

    var isAnswered: Bool { guess != nil }
    var isCorrect: Bool { guess == card.symbol }
}
