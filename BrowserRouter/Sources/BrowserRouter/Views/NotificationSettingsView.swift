import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var ruleStore: RuleStore

    private let availableSounds = ["Pop", "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero", "Morse", "Ping", "Purr", "Sosumi", "Submarine", "Tink"]

    var body: some View {
        ScrollView {
            GlassEffectContainer {
                VStack(spacing: 12) {
                    SettingsCard {
                        Toggle("Show notification banner", isOn: $ruleStore.notificationSettings.showBanner)
                        Text("Display a macOS notification when a URL is routed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    SettingsCard {
                        Toggle("Flash menu bar icon", isOn: $ruleStore.notificationSettings.flashIcon)
                        Text("Briefly highlight the menu bar icon green")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    SettingsCard {
                        Toggle("Track recent URLs", isOn: $ruleStore.notificationSettings.trackRecent)
                        Text("Show recently routed URLs in the menu bar dropdown")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if ruleStore.notificationSettings.trackRecent {
                            Stepper(
                                "Keep \(ruleStore.notificationSettings.maxRecentURLs) recent URLs",
                                value: $ruleStore.notificationSettings.maxRecentURLs,
                                in: 5...50,
                                step: 5
                            )
                        }
                    }

                    SettingsCard {
                        Toggle("Play sound", isOn: $ruleStore.notificationSettings.playSound)

                        if ruleStore.notificationSettings.playSound {
                            Picker("Sound", selection: $ruleStore.notificationSettings.soundName) {
                                ForEach(availableSounds, id: \.self) { sound in
                                    Text(sound).tag(sound)
                                }
                            }

                            Button("Preview") {
                                NSSound(named: NSSound.Name(ruleStore.notificationSettings.soundName))?.play()
                            }
                        }
                    }
                }
                .padding(8)
            }
        }
        .scrollClipDisabled()
        .frame(minWidth: 500)
        .onChange(of: ruleStore.notificationSettings) {
            ruleStore.save()
        }
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}
