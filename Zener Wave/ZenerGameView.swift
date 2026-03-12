// ZenerGameView.swift
// UI for the Zener card guessing game

import SwiftUI
import SwiftData

struct ZenerGameView: View {
    let roundCount: Int

    @StateObject private var game = ZenerGame()
    @State private var flashedSymbol: ZenerSymbol? = nil
    @State private var flashTask: Task<Void, Never>? = nil

    // F1: Persist completed sessions
    @Environment(\.modelContext) private var modelContext

    // F3: User's preferred round count for "Play Again" (persisted)
    @AppStorage("preferredRoundCount") private var preferredRoundCount: Int = 25

    // Sound toggle, shared with SettingsView
    @AppStorage("soundsEnabled") private var soundsEnabled: Bool = true

    // F15: Feedback toggle — when off, no flash/sound/haptic/streak during play
    @AppStorage("feedbackEnabled") private var feedbackEnabled: Bool = true

    // F9: Timed mode — countdown per round
    @AppStorage("timedModeEnabled") private var timedModeEnabled: Bool = false
    @AppStorage("timedModeSeconds") private var timedModeSeconds: Int = 5
    // Fix #11: timeRemaining is synced from timedModeSeconds in onAppear
    @State private var timeRemaining: Int = 5
    @State private var timerTask: Task<Void, Never>? = nil
    @State private var showTimeoutBanner: Bool = false

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
        // Fix #7: Simplified — just start the game with the correct round count
        .onAppear {
            // Fix #11: sync timeRemaining from AppStorage on appear
            timeRemaining = timedModeSeconds
            if game.roundCount != roundCount {
                game.startNewGame(numberOfRounds: roundCount)
            }
            startTimerIfNeeded()
        }
        // Fix #4 & #5: Cancel all tasks when view leaves screen
        .onDisappear {
            flashTask?.cancel()
            timerTask?.cancel()
        }
        // F9: Reset countdown on each new round
        .onChange(of: game.currentIndex) { _, _ in
            startTimerIfNeeded()
        }
        // F1: Save session when game completes
        .onChange(of: game.isComplete) { _, isComplete in
            if isComplete {
                timerTask?.cancel()
                let session = GameSession.from(rounds: game.rounds)
                modelContext.insert(session)
                // Fix #2: Explicitly persist so data isn't lost if app terminates quickly
                try? modelContext.save()
            }
        }
    }

    // MARK: - Play View

    private var playView: some View {
        VStack(spacing: 20) {
            // Fix #18: animate progress bar between rounds
            ProgressView(value: game.progress)
                .tint(.accentColor)
                .animation(.easeInOut(duration: 0.3), value: game.progress)

            // F5: Streak indicator (hidden in blind mode)
            // Fix #17: timeout banner shown in place of streak area
            if showTimeoutBanner {
                Text("Time's up!")
                    .font(.caption).bold()
                    .foregroundStyle(.red)
                    .transition(.opacity)
            } else if feedbackEnabled {
                streakIndicator
            } else {
                Text(" ").font(.subheadline) // stable placeholder
            }

            HStack {
                Text("Round \(game.currentIndex + 1) of \(game.roundCount)")
                    .font(.headline)

                // F9: Countdown timer
                if timedModeEnabled {
                    Spacer()
                    Text("\(timeRemaining)s")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(timeRemaining <= 2 ? .red : .secondary)
                        .contentTransition(.numericText())
                        .animation(.default, value: timeRemaining)
                }
            }

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
                        // Flash only shown when feedback is enabled
                        .opacity(flashedSymbol == nil || !feedbackEnabled ? 1 : 0)

                        if let flash = flashedSymbol, feedbackEnabled {
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
                if let correct = game.makeGuess(symbol) {
                    // F15: Only give feedback if enabled
                    if feedbackEnabled {
                        // F4: Play sound
                        if soundsEnabled {
                            if correct { SoundManager.playCorrect() }
                            else { SoundManager.playIncorrect() }
                        }
                    } else {
                        // Blind mode: skip flash, cancel timer-driven flash
                        flashTask?.cancel()
                        flashedSymbol = nil
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Timer helpers (F9)

    private func startTimerIfNeeded() {
        timerTask?.cancel()
        showTimeoutBanner = false
        guard timedModeEnabled, !game.isComplete else { return }
        timeRemaining = timedModeSeconds
        timerTask = Task { @MainActor in
            while timeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                timeRemaining -= 1
            }
            guard !Task.isCancelled, !game.isComplete else { return }
            // Fix #8: use a random symbol for the forced guess so it is not
            // biased toward one symbol (circle) skewing score statistics
            let timeoutGuess = ZenerSymbol.allCases.randomElement() ?? .circle
            _ = game.makeGuess(timeoutGuess)
            flashTask?.cancel()
            flashedSymbol = nil
            // Fix #17: briefly show "Time's up!" banner
            withAnimation { showTimeoutBanner = true }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation { showTimeoutBanner = false }
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

                // Play Again + F6: Share
                let interp = ScoreInterpreter.interpret(
                    score: game.score,
                    totalRounds: game.roundCount
                )
                VStack(spacing: 10) {
                    Button("Play Again") {
                        flashTask?.cancel()
                        flashedSymbol = nil
                        game.startNewGame(numberOfRounds: roundCount)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 12) {
                        NavigationLink {
                            RoundPickerView()
                        } label: {
                            Label("Change Length", systemImage: "arrow.left.arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        // F6: Share results
                        ShareLink(
                            item: "I scored \(game.score)/\(game.roundCount) on the Zener Wave ESP test — \(interp.headline.lowercased()). Can you beat it?",
                            preview: SharePreview("Zener Wave Result", image: Image(systemName: "sparkles"))
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
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
                    // F15: Only haptic/flash in feedback mode
                    if feedbackEnabled {
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
                    }
                    // F9: Cancel the countdown timer when a guess is made
                    timerTask?.cancel()
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
                .accessibilityLabel("Guess \(symbol.name)")
            }
        }
    }
}

#Preview {
    NavigationStack { ZenerGameView(roundCount: 10) }
        .modelContainer(for: GameSession.self, inMemory: true)
}
