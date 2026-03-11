import SwiftUI

/// Welcome screen shown on every launch. Describes Zener cards and lets the
/// user pick how many rounds they want before starting.
struct FirstLaunchPickerView: View {
    @Binding var preferredRoundCount: Int
    var onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let wikiURL = URL(string: "https://en.wikipedia.org/wiki/Zener_cards#:~:text=Zener%20cards%20are%20cards%20used,colleague%2C%20parapsychologist%20J.%20B.%20Rhine%20(1895%E2%80%931980).")!

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: Header
                VStack(spacing: 12) {
                    Text("★")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text("Zener Wave")
                        .font(.largeTitle).bold()
                }
                .padding(.top, 40)

                // MARK: What are Zener cards?
                VStack(alignment: .leading, spacing: 10) {
                    Text("What are Zener cards?")
                        .font(.headline)

                    Text("Zener cards were developed in the 1930s by perceptual psychologist Karl Zener to test for extrasensory perception (ESP). Each deck contains 25 cards — 5 each of five simple symbols: circle, cross, wavy lines, square, and star.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("In a classic test, a sender concentrates on a hidden card while the receiver tries to guess the symbol using only intuition. Pure chance gives a 20% hit rate (5 correct out of 25). Scoring significantly above chance is taken as evidence of ESP.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Link(destination: wikiURL) {
                        Label("Learn more on Wikipedia", systemImage: "arrow.up.right.square")
                            .font(.subheadline)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 24)

                // MARK: How to play
                VStack(alignment: .leading, spacing: 10) {
                    Text("How to play")
                        .font(.headline)

                    Text("A card is drawn at random and hidden from you. Focus your mind, then tap the symbol you feel is correct. Your score and a statistical interpretation are shown at the end — the app will tell you how likely your result was by chance alone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                // MARK: Round picker
                VStack(spacing: 12) {
                    Text("How many rounds would you like?")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        ForEach([5, 10, 25], id: \.self) { count in
                            Button {
                                preferredRoundCount = count
                                dismiss()
                                onStart()
                            } label: {
                                HStack {
                                    Text("\(count) rounds")
                                        .font(.headline)
                                    Spacer()
                                    if preferredRoundCount == count {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(preferredRoundCount == count ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }

    }
}

#Preview {
    FirstLaunchPickerView(preferredRoundCount: .constant(25)) {}
}
