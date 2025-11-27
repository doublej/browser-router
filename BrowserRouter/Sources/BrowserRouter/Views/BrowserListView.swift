import SwiftUI

struct BrowserListView: View {
    @EnvironmentObject var browserDetector: BrowserDetector
    @EnvironmentObject var ruleStore: RuleStore

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                GlassEffectContainer {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(browserDetector.browsers.enumerated()), id: \.element.id) { index, browser in
                            BrowserRowView(
                                browser: browser,
                                letter: letterFor(index: index),
                                isSystemDefault: browser.id == browserDetector.defaultBrowserID,
                                isFallback: browser.id == ruleStore.fallbackBrowserID,
                                onSetFallback: { ruleStore.setFallbackBrowser(browser.id) },
                                onClearFallback: { ruleStore.setFallbackBrowser(nil) }
                            )
                        }
                    }
                    .padding(8)
                }
            }
            .scrollClipDisabled()

            HStack {
                Button("Refresh") {
                    browserDetector.refresh()
                }

                Spacer()

                Text("\(browserDetector.browsers.count) browsers detected")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 650)
    }

    private func letterFor(index: Int) -> String {
        let letterIndex = index % 26
        let scalar = UnicodeScalar("A".unicodeScalars.first!.value + UInt32(letterIndex))!
        return String(Character(scalar))
    }
}

struct BrowserRowView: View {
    let browser: Browser
    let letter: String
    let isSystemDefault: Bool
    let isFallback: Bool
    let onSetFallback: () -> Void
    let onClearFallback: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(letter)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 6))

            if let icon = browser.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading) {
                HStack {
                    Text(browser.name)
                        .font(.body)

                    if isSystemDefault {
                        Text("System Default")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                    }

                    if isFallback {
                        Text("Default Route")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                    }
                }

                Text(browser.id)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isFallback {
                Button("Clear") {
                    onClearFallback()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            } else {
                Button("Set as Default") {
                    onSetFallback()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
    }
}
