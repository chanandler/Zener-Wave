import SwiftUI

/// Second step of the app flow. The player picks how many rounds they want,
/// then navigates into ZenerGameView.
struct RoundPickerView: View {
    @AppStorage("preferredRoundCount") private var preferredRoundCount: Int = 25

    private let options: [(count: Int, label: String, description: String)] = [
        (5,  "Quick",    "5 rounds — a fast trial"),
        (10, "Standard", "10 rounds — the classic length"),
        (25, "Full",     "25 rounds — the traditional full test"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Choose your test length")
                            .font(.title2).bold()

                        Text("Select how many rounds you'd like to play. A longer test gives a more statistically significant result.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        ForEach(options, id: \.count) { option in
                            NavigationLink {
                                ZenerGameView(roundCount: option.count)
                            } label: {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(option.label)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(option.description)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(preferredRoundCount == option.count
                                              ? Color.accentColor.opacity(0.12)
                                              : Color(.secondarySystemGroupedBackground))
                                )
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                preferredRoundCount = option.count
                            })
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Test Length")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RoundPickerView()
    }
}
