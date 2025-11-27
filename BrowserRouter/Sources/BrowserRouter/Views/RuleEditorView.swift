import SwiftUI

struct RuleEditorView: View {
    @EnvironmentObject var browserDetector: BrowserDetector

    let rule: RoutingRule?
    let onSave: (RoutingRule) -> Void
    let onCancel: () -> Void

    @State private var pattern: String = ""
    @State private var matchType: MatchType = .domain
    @State private var selectedBrowserID: String = ""
    @State private var selectedProfileID: String?
    @State private var portRangeString: String = ""
    @State private var enabled: Bool = true

    private let maxVisibleBrowsers = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 28)

            GlassEffectContainer {
                VStack(alignment: .leading, spacing: 0) {
                    // Step 1: Match Type
                    SectionCard(step: 1, title: "Match Type", subtitle: "How should URLs be matched?") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                ForEach(MatchType.allCases, id: \.self) { type in
                                    MatchTypeChip(
                                        type: type,
                                        isSelected: matchType == type,
                                        onSelect: { matchType = type }
                                    )
                                }
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.7))
                                Text(matchType.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 16)

                    // Step 2: Pattern + Port
                    SectionCard(step: 2, title: "Pattern", subtitle: "Enter the URL pattern to match") {
                        VStack(alignment: .leading, spacing: 12) {
                            patternField

                            HStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "network")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text("Port:")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                TextField("", text: $portRangeString, prompt: Text("any").foregroundColor(.secondary.opacity(0.4)))
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13, design: .monospaced))
                                    .frame(width: 100)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .glassEffect(.regular, in: .rect(cornerRadius: 6))

                                Text("e.g. 3000 or 8000-8999")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.6))

                                Spacer()
                            }
                        }
                    }
                    .padding(.bottom, 16)

                    // Step 3: Browser
                    SectionCard(step: 3, title: "Open With", subtitle: "Select the browser for matching URLs") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                ForEach(Array(mainBrowsers.enumerated()), id: \.element.id) { index, browser in
                                    BrowserTile(
                                        browser: browser,
                                        shortcut: letterFor(index: index),
                                        isSelected: selectedBrowserID == browser.id,
                                        onSelect: { selectBrowser(browser.id) }
                                    )
                                }

                                if !extraBrowsers.isEmpty {
                                    moreBrowsersMenu
                                }
                            }

                            if let browser = selectedBrowser, browser.supportsProfiles {
                                profileSelector(for: browser)
                            }
                        }
                    }
                    .padding(.bottom, 20)

                    // Options row
                    HStack {
                        Toggle(isOn: $enabled) {
                            HStack(spacing: 6) {
                                Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(enabled ? .green : .secondary)
                                    .font(.system(size: 14))
                                Text("Rule enabled")
                                    .font(.system(size: 13))
                            }
                        }
                        .toggleStyle(.button)
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }

            Divider()
                .padding(.vertical, 16)

            actionButtons
        }
        .padding(28)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { loadRule() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Button(action: onCancel) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Rules")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(rule == nil ? "New Rule" : "Edit Rule")
                    .font(.system(size: 15, weight: .semibold))
                Text(rule == nil ? "Create a URL routing rule" : "Modify rule settings")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Balance spacer
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                Text("Rules")
            }
            .font(.system(size: 13))
            .opacity(0)
        }
    }

    // MARK: - Pattern Field

    @ViewBuilder
    private var patternField: some View {
        HStack(spacing: 0) {
            if matchType == .domain {
                PatternPrefix("https://")
            } else if matchType == .contains {
                PatternPrefix("...[")
            }

            TextField("", text: $pattern, prompt: Text(matchType.placeholder).foregroundColor(.secondary.opacity(0.4)))
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .monospaced))

            if matchType == .domain {
                PatternSuffix("/...")
            } else if matchType == .contains {
                PatternSuffix("]...")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }

    // MARK: - Browser Section

    private var mainBrowsers: [Browser] {
        Array(browserDetector.browsers.prefix(maxVisibleBrowsers))
    }

    private var extraBrowsers: [Browser] {
        Array(browserDetector.browsers.dropFirst(maxVisibleBrowsers))
    }

    private var selectedBrowser: Browser? {
        browserDetector.browser(for: selectedBrowserID)
    }

    private func selectBrowser(_ id: String) {
        selectedBrowserID = id
        selectedProfileID = nil
    }

    @ViewBuilder
    private func profileSelector(for browser: Browser) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("Profile:")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            FlowLayout(spacing: 8) {
                ProfileChip(
                    name: "Default",
                    isSelected: selectedProfileID == nil,
                    onSelect: { selectedProfileID = nil }
                )

                ForEach(browser.profiles) { profile in
                    ProfileChip(
                        name: profile.name,
                        isSelected: selectedProfileID == profile.id,
                        onSelect: { selectedProfileID = profile.id }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var moreBrowsersMenu: some View {
        Menu {
            ForEach(Array(extraBrowsers.enumerated()), id: \.element.id) { _, browser in
                Button(action: { selectBrowser(browser.id) }) {
                    HStack {
                        if let icon = browser.icon {
                            Image(nsImage: icon)
                        }
                        Text(browser.name)
                        if selectedBrowserID == browser.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if let selectedExtra = extraBrowsers.first(where: { $0.id == selectedBrowserID }),
                       let icon = selectedExtra.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                            Text("\(extraBrowsers.count)")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .frame(width: 56, height: 56)
                .background(extraBrowserSelected ? Color.accentColor.opacity(0.15) : Color.clear, in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(extraBrowserSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: extraBrowserSelected ? 2 : 1)
                )

                Text("More")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
        .frame(width: 72)
    }

    private var extraBrowserSelected: Bool {
        extraBrowsers.contains { $0.id == selectedBrowserID }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 80)
            }
            .keyboardShortcut(.cancelAction)
            .buttonStyle(.bordered)

            Spacer()

            Button(action: save) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Save Rule")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(width: 100)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(pattern.isEmpty || selectedBrowserID.isEmpty)
        }
    }

    // MARK: - Helpers

    private func letterFor(index: Int) -> String {
        let letterIndex = index % 26
        let scalar = UnicodeScalar("A".unicodeScalars.first!.value + UInt32(letterIndex))!
        return String(Character(scalar))
    }

    private func loadRule() {
        if let rule = rule {
            pattern = rule.pattern
            matchType = rule.matchType
            selectedBrowserID = rule.browserID
            selectedProfileID = rule.profileID
            portRangeString = rule.portRange?.displayString ?? ""
            enabled = rule.enabled
        } else {
            selectedBrowserID = browserDetector.browsers.first?.id ?? ""
        }
    }

    private func save() {
        let newRule = RoutingRule(
            id: rule?.id ?? UUID(),
            pattern: pattern,
            matchType: matchType,
            browserID: selectedBrowserID,
            profileID: selectedProfileID,
            portRange: PortRange.parse(portRangeString),
            enabled: enabled,
            priority: rule?.priority ?? 0
        )
        onSave(newRule)
    }
}

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    let step: Int
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                // Step indicator
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 24, height: 24)
                    Text("\(step)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.bottom, 14)

            // Content
            content()
                .padding(.leading, 36)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

// MARK: - Match Type Chip

struct MatchTypeChip: View {
    let type: MatchType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 10, weight: .semibold))
                Text(type.displayName)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.accentColor : Color.clear, in: .rect(cornerRadius: 10))
            .glassEffect(isSelected ? .clear : .regular, in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch type {
        case .contains: "text.magnifyingglass"
        case .domain: "globe"
        case .wildcard: "asterisk"
        case .regex: "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - Browser Tile

struct BrowserTile: View {
    let browser: Browser
    let shortcut: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    if let icon = browser.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    }

                    // Shortcut badge
                    Text(shortcut)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.accentColor, in: .rect(cornerRadius: 4))
                        .offset(x: 6, y: 6)
                }
                .frame(width: 56, height: 56)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear, in: .rect(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )

                Text(browser.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .frame(width: 64)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pattern Decorators

struct PatternPrefix: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.5))
    }
}

struct PatternSuffix: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.5))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: containerWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Profile Chip

struct ProfileChip: View {
    let name: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 4) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 12))
                    .frame(width: 12, height: 12)
                Text(name)
                    .font(.system(size: 9, weight: .regular))
                    .lineLimit(1)
            }
            .frame(minWidth: 60)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.accentColor : Color.clear, in: .rect(cornerRadius: 8))
            .glassEffect(isSelected ? .clear : .regular, in: .rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
