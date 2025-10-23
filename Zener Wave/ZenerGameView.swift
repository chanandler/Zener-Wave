// ZenerGameView.swift
// UI for the Zener card guessing game

import SwiftUI
import Combine

// MARK: - Model
enum ZenerSymbol: String, CaseIterable, Identifiable, Equatable {
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

final class ZenerGame: ObservableObject {
    @Published private(set) var rounds: [ZenerRound] = []
    @Published private(set) var currentIndex: Int = 0

    var isComplete: Bool { currentIndex >= rounds.count }
    var progress: Double { rounds.isEmpty ? 0 : Double(currentIndex) / Double(rounds.count) }
    var score: Int { rounds.filter { $0.isCorrect }.count }

    init(numberOfRounds: Int = 25) {
        startNewGame(numberOfRounds: numberOfRounds)
    }

    func startNewGame(numberOfRounds: Int = 25) {
        let symbols = ZenerSymbol.allCases
        rounds = (0..<numberOfRounds).map { _ in ZenerRound(card: ZenerCard(symbol: symbols.randomElement()!)) }
        currentIndex = 0
    }

    func makeGuess(_ symbol: ZenerSymbol) {
        guard !isComplete else { return }
        rounds[currentIndex].guess = symbol
        currentIndex += 1
    }

    func currentRound() -> ZenerRound? {
        guard !isComplete else { return nil }
        return rounds[currentIndex]
    }
}

// MARK: - View
struct ZenerGameView: View {
    @StateObject private var game = ZenerGame()
    @State private var flashedSymbol: ZenerSymbol? = nil
    @State private var showingTipJar = false

    var body: some View {
        Group {
            if game.isComplete {
                resultView
            } else {
                playView
            }
        }
        .animation(.easeInOut, value: game.currentIndex)
        .padding()
        .navigationTitle("Zener Test")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingTipJar = true
                } label: {
                    Image(systemName: "heart.fill")
                }
                .accessibilityLabel("Tip Jar")
            }
        }
        .sheet(isPresented: $showingTipJar) {
            TipJarView()
        }
    }

    private var playView: some View {
        VStack(spacing: 24) {
            ProgressView(value: game.progress)
                .tint(.accentColor)

            Text("Round \(game.currentIndex + 1) of \(game.rounds.count)")
                .font(.headline)

            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .frame(height: 180)
                .overlay(
                    ZStack {
                        VStack {
                            Text("Focus and guess the symbol")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("?")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                        }
                        .opacity(flashedSymbol == nil ? 1 : 0)

                        if let flash = flashedSymbol {
                            Text(flash.rawValue)
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                )

            Text("Choose a symbol")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            symbolGrid { symbol in
                game.makeGuess(symbol)
            }

            Spacer(minLength: 0)
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Text("Results")
                .font(.largeTitle).bold()

            Text("Score: \(game.score) / \(game.rounds.count)")
                .font(.title2)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(game.rounds.enumerated()), id: \.offset) { index, round in
                        HStack(spacing: 12) {
                            Text("\(index + 1).")
                                .frame(width: 28, alignment: .trailing)
                                .foregroundStyle(.secondary)
                            Text(round.card.symbol.rawValue)
                                .font(.title3)
                                .frame(width: 36)
                            Image(systemName: round.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(round.isCorrect ? .green : .red)
                            if let guess = round.guess {
                                Text(guess.rawValue)
                                    .frame(width: 36)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxHeight: 280)

            Button("Play Again") {
                game.startNewGame()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical)
    }

    @ViewBuilder
    private func symbolGrid(onSelect: @escaping (ZenerSymbol) -> Void) -> some View {
        let symbols = ZenerSymbol.allCases
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
            ForEach(symbols) { symbol in
                Button {
#if canImport(UIKit)
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
#endif
withAnimation(.easeInOut(duration: 0.15)) {
    flashedSymbol = symbol
}
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
    withAnimation(.easeOut(duration: 0.15)) {
        flashedSymbol = nil
    }
}
onSelect(symbol)
                } label: {
                    VStack(spacing: 6) {
                        Text(symbol.rawValue)
                            .font(.system(size: 28))
                        Text(symbol.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(symbol.name)
            }
        }
    }
}

#Preview {
    NavigationStack { ZenerGameView() }
}
