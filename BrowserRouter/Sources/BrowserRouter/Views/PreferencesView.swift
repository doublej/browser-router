import SwiftUI

struct PreferencesView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RuleListView()
                .tabItem { Label("Rules", systemImage: "list.bullet") }
                .tag(0)

            BrowserListView()
                .tabItem { Label("Browsers", systemImage: "globe") }
                .tag(1)

            NotificationSettingsView()
                .tabItem { Label("Notifications", systemImage: "bell") }
                .tag(2)

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(3)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - About View

struct AboutView: View {
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.accentColor)

            // App name and version
            VStack(spacing: 4) {
                Text("Browser Router")
                    .font(.system(size: 24, weight: .semibold))

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Description
            Text("Route URLs to different browsers based on custom rules.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Spacer()

            // Links
            VStack(spacing: 12) {
                Button(action: openWebsite) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text("Visit Website")
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.link)

                Text("Made by Jurrejan")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .frame(minWidth: 400)
    }

    private func openWebsite() {
        guard let url = URL(string: "https://www.jurrejan.com") else { return }
        NSWorkspace.shared.open(url)
    }
}
