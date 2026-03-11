// HistoryView.swift
// Session history and aggregate statistics

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \GameSession.date, order: .reverse) private var sessions: [GameSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Games Yet",
                    systemImage: "chart.bar",
                    description: Text("Complete a game to see your history here.")
                )
            } else {
                statisticsSection
                sessionsSection
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !sessions.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        for session in sessions {
                            modelContext.delete(session)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Clear History")
                }
            }
        }
    }

    // MARK: - Computed Stats

    private var totalGames: Int { sessions.count }

    private var allTimeAccuracy: Double {
        guard !sessions.isEmpty else { return 0 }
        let totalScore = sessions.reduce(0) { $0 + $1.score }
        let totalRounds = sessions.reduce(0) { $0 + $1.roundCount }
        guard totalRounds > 0 else { return 0 }
        return Double(totalScore) / Double(totalRounds) * 100
    }

    private var bestSession: GameSession? {
        sessions.max { a, b in a.accuracyPercent < b.accuracyPercent }
    }

    private var recentTrend: String {
        let recent = Array(sessions.prefix(5))
        guard recent.count >= 3 else { return "—" }
        let recentAccuracy = Double(recent.reduce(0) { $0 + $1.score }) /
                             Double(recent.reduce(0) { $0 + $1.roundCount }) * 100
        let diff = recentAccuracy - allTimeAccuracy
        if abs(diff) < 2 { return "Steady" }
        return diff > 0 ? "Improving ↑" : "Declining ↓"
    }

    // MARK: - Sections

    @ViewBuilder
    private var statisticsSection: some View {
        Section("Statistics") {
            LabeledContent("Games Played", value: "\(totalGames)")
            LabeledContent("All-Time Accuracy", value: String(format: "%.1f%%", allTimeAccuracy))
            if let best = bestSession {
                LabeledContent("Best Score", value: "\(best.score)/\(best.roundCount) (\(String(format: "%.0f%%", best.accuracyPercent)))")
            }
            LabeledContent("Recent Trend", value: recentTrend)
        }
    }

    @ViewBuilder
    private var sessionsSection: some View {
        Section("Past Sessions") {
            ForEach(sessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(session.score)/\(session.roundCount)")
                            .font(.headline)
                        Text(session.date, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.0f%%", session.accuracyPercent))
                        .font(.subheadline)
                        .foregroundStyle(
                            session.accuracyPercent > 25 ? .green :
                            session.accuracyPercent < 15 ? .orange : .secondary
                        )
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
