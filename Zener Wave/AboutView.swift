import SwiftUI

struct AboutView: View {
    @State private var didCopyVersion = false

    private var appDisplayName: String {
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !name.isEmpty {
            return name
        }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    
    private func copyVersionToClipboard() {
        // Fix #16: guard prevents re-triggering the alert if it is already showing
        guard !didCopyVersion else { return }
        let versionString = "\(appVersion) (\(buildNumber))"
        #if canImport(UIKit)
        UIPasteboard.general.string = versionString
        // Haptic feedback on iPhone after copying
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(versionString, forType: .string)
        #endif
        didCopyVersion = true
    }

    var body: some View {
        List {
            Section("About") {
                HStack(spacing: 16) {
                    Image(systemName: "app")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)

                    Text(appDisplayName)
                        .font(.headline)
                }
                .padding(.vertical, 4)

                // Fix #15: show version only once, in the cleaner label/value row
                AppVersionRow(title: "Version", value: "\(appVersion) (\(buildNumber))")
            }

            Section("Zener Cards") {
                Text("Zener cards were developed in the 1930s by perceptual psychologist Karl Zener to test for extrasensory perception (ESP). Each deck contains 25 cards — 5 each of five simple symbols: circle, cross, wavy lines, square, and star.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                Text("In a classic test, a sender concentrates on a hidden card while the receiver tries to guess the symbol using only intuition. Pure chance gives a 20% hit rate (5 correct out of 25). Scoring significantly above chance is taken as evidence of ESP.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)

                Link(destination: URL(string: "https://en.wikipedia.org/wiki/Zener_cards#:~:text=Zener%20cards%20are%20cards%20used,colleague%2C%20parapsychologist%20J.%20B.%20Rhine%20(1895%E2%80%931980).")!) {
                    Label("Learn more on Wikipedia", systemImage: "arrow.up.right.square")
                        .font(.subheadline)
                }
            }

            Section("Actions") {
                Button {
                    copyVersionToClipboard()
                } label: {
                    Label("Copy Version", systemImage: "doc.on.doc")
                }
            }

            Section(footer:
                HStack {
                    Spacer()
                    Button {
                        copyVersionToClipboard()
                    } label: {
                        Label("Copy Version", systemImage: "doc.on.doc")
                            .padding(.horizontal)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Copy Version")
                    Spacer()
                }
                .padding(.vertical, 12)
            ) {
                EmptyView()
            }
        }
        .navigationTitle("About")
        .toolbarRole(.automatic)
        .navigationBarTitleDisplayMode(.inline)
        // Fix #14: removed the misleading info.circle toolbar button that was
        // silently copying to clipboard instead of showing information
        .alert("Copied", isPresented: $didCopyVersion) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Version \(appVersion) (\(buildNumber)) copied to clipboard.")
        }
    }
}

private struct AppVersionRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospaced()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
