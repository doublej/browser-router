import SwiftUI

struct BrowserListView: View {
    @EnvironmentObject var browserDetector: BrowserDetector

    var body: some View {
        VStack(spacing: 16) {
            List(Array(browserDetector.browsers.enumerated()), id: \.element.id) { index, browser in
                HStack(spacing: 12) {
                    Text(letterFor(index: index))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .cornerRadius(6)

                    if let icon = browser.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text(browser.name)
                                .font(.body)

                            if browser.id == browserDetector.defaultBrowserID {
                                Text("System Default")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }

                        Text(browser.id)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)

            HStack {
                Button("Refresh") {
                    browserDetector.refresh()
                }

                Spacer()

                Text("\(browserDetector.browsers.count) browsers detected")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func letterFor(index: Int) -> String {
        let letterIndex = index % 26
        let scalar = UnicodeScalar("A".unicodeScalars.first!.value + UInt32(letterIndex))!
        return String(Character(scalar))
    }
}
