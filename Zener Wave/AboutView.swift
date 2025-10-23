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

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appDisplayName)
                            .font(.headline)
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospaced()
                    }
                }
                .padding(.vertical, 4)

                AppVersionRow(title: "Version", value: "\(appVersion) (\(buildNumber))")
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    copyVersionToClipboard()
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About")
            }
        }
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
