// ZenerGameView.swift
// UI for the Zener card guessing game

import SwiftUI
import SwiftData

struct ZenerGameView: View {
    @StateObject private var game = ZenerGame()
    @State private var flashedSymbol: ZenerSymbol? = nil
    @State private var flashTask: Task<Void, Never>? = nil
    @State private var showingTipJar = false

    // F1: Persist completed sessions
    @Environment(\.modelContext) private var modelContext

    // F3: User's preferred round count, persisted across launches
    @AppStorage("preferredRoundCount") private var preferredRoundCount: Int = 25

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
                HStack(spacing: 16) {
                    // F1: History
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                    .accessibilityLabel("History")

                    NavigationLink {
                        AboutView()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("About")

                    Button {
                        showingTipJar = true
                    } label: {
                        Image(systemName: "heart.fill")
                    }
                    .accessibilityLabel("Tip Jar")
                }
            }
        }
        .sheet(isPresented: $showingTipJar) {
            TipJarView()
        }
        // F3: Apply preferred round count on first launch
        .onAppear {
            if game.roundCount == 25 && preferredRoundCount != 25 {
                game.startNewGame(numberOfRounds: preferredRoundCount)
            }
        }
        // F1: Save session when game completes
        .onChange(of: game.isComplete) { _, isComplete in
            if isComplete {
                let session = GameSession.from(rounds: game.rounds)
                modelContext.insert(session)
            }
        }
    }

    // MARK: - Play View

    private var playView: some View {
        VStack(spacing: 20) {
            ProgressView(value: game.progress)
                .tint(.accentColor)

            // F5: Streak indicator
            streakIndicator

            Text("Round \(game.currentIndex + 1) of \(game.roundCount)")
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
                // F4: Play sound based on correctness
                if let correct = game.makeGuess(symbol) {
                    if correct {
                        SoundManager.playCorrect()
                    } else {
                        SoundManager.playIncorrect()
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    // F5: Streak banner shown during play
    @ViewBuilder
    private var streakIndicator: some View {
        if game.streakJustBroken {
            Text("Streak broken")
                .font(.caption).bold()
                .foregroundStyle(.orange)
                .transition(.opacity)
                .task {
                    try? await Task.sleep(for: .seconds(1.2))
                    withAnimation { game.clearStreakBroken() }
                }
        } else if game.currentStreak >= 2 {
            Text("\(game.currentStreak) in a row!")
                .font(.subheadline).bold()
                .foregroundStyle(.green)
                .transition(.scale.combined(with: .opacity))
        } else {
            // Placeholder to keep layout stable
            Text(" ").font(.subheadline)
        }
    }

    // MARK: - Result View

    private var resultView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Results")
                    .font(.largeTitle).bold()

                Text("Score: \(game.score) / \(game.roundCount)")
                    .font(.title2)

                // F5: Best streak
                if game.bestStreak >= 2 {
                    Text("Best streak: \(game.bestStreak) in a row")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // F2: Score interpretation
                interpretationView

                // Per-round list
                roundList

                // F7: Symbol accuracy breakdown
                symbolBreakdownView

                Divider()

                // F3: Round count picker
                VStack(spacing: 8) {
                    Text("Rounds for next game")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("Rounds", selection: $preferredRoundCount) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("25").tag(25)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                // Play Again + F6: Share
                HStack(spacing: 12) {
                    Button("Play Again") {
                        flashTask?.cancel()
                        flashedSymbol = nil
                        game.startNewGame(numberOfRounds: preferredRoundCount)
                    }
                    .buttonStyle(.borderedProminent)

                    // F6: Share results
                    let interp = ScoreInterpreter.interpret(
                        score: game.score,
                        totalRounds: game.roundCount
                    )
                    ShareLink(
                        item: "I scored \(game.score)/\(game.roundCount) on the Zener Wave ESP test — \(interp.headline.lowercased()). Can you beat it?",
                        preview: SharePreview("Zener Wave Result", image: Image(systemName: "sparkles"))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical)
        }
    }

    // F2: Statistical interpretation panel
    @ViewBuilder
    private var interpretationView: some View {
        let interp = ScoreInterpreter.interpret(score: game.score, totalRounds: game.roundCount)
        VStack(spacing: 6) {
            Text(interp.headline)
                .font(.title3).bold()
                .foregroundStyle(
                    interp.deviationFromChance > 0 ? .green :
                    interp.deviationFromChance < -1 ? .orange : .secondary
                )
            Text(interp.flavourText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Chance predicts \(Int(interp.expectedByChance))/\(game.roundCount) · Odds: \(interp.oddsString)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    // Per-round scroll list
    @ViewBuilder
    private var roundList: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(game.rounds.enumerated()), id: \.element.id) { index, round in
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
        .frame(maxHeight: 280)
        .clipped()
    }

    // F7: Per-symbol accuracy breakdown
    @ViewBuilder
    private var symbolBreakdownView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Symbol Breakdown")
                .font(.headline)

            ForEach(ZenerSymbol.allCases) { symbol in
                let appearances = game.rounds.filter { $0.card.symbol == symbol }.count
                let correct = game.rounds.filter { $0.card.symbol == symbol && $0.isCorrect }.count
                HStack(spacing: 10) {
                    Text(symbol.rawValue)
                        .font(.title3)
                        .frame(width: 28)
                    Text(symbol.name)
                        .font(.subheadline)
                        .frame(width: 54, alignment: .leading)
                    Text("\(correct)/\(appearances)")
                        .monospacedDigit()
                        .font(.subheadline)
                        .frame(width: 36)
                    if appearances > 0 {
                        ProgressView(value: Double(correct), total: Double(appearances))
                            .tint(
                                correct == appearances ? .green :
                                correct == 0 ? .red : .accentColor
                            )
                    } else {
                        ProgressView(value: 0)
                            .tint(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Symbol Grid

    @ViewBuilder
    private func symbolGrid(onSelect: @escaping (ZenerSymbol) -> Void) -> some View {
        let symbols = ZenerSymbol.allCases
        HStack(spacing: 12) {
            ForEach(symbols) { symbol in
                Button {
                    #if canImport(UIKit)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    #endif
                    withAnimation(.easeInOut(duration: 0.15)) {
                        flashedSymbol = symbol
                    }
                    flashTask?.cancel()
                    flashTask = Task {
                        try? await Task.sleep(for: .seconds(3))
                        guard !Task.isCancelled else { return }
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
        .modelContainer(for: GameSession.self, inMemory: true)
}
