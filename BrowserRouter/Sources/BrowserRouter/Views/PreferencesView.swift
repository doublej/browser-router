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
        }
        .frame(minWidth: 600, minHeight: 400)
        .padding()
    }
}
