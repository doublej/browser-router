import SwiftUI

struct RuleListView: View {
    @EnvironmentObject var ruleStore: RuleStore
    @EnvironmentObject var browserDetector: BrowserDetector
    @State private var editingRule: RoutingRule?
    @State private var isEditing = false
    @State private var testURL = "https://"
    @State private var testResult: String?

    var body: some View {
        Group {
            if isEditing {
                RuleEditorView(
                    rule: editingRule,
                    onSave: { newRule in
                        if editingRule != nil {
                            ruleStore.update(newRule)
                        } else {
                            ruleStore.add(newRule)
                        }
                        isEditing = false
                        editingRule = nil
                    },
                    onCancel: {
                        isEditing = false
                        editingRule = nil
                    }
                )
            } else {
                ruleListContent
            }
        }
        .frame(minWidth: 650)
    }

    private var ruleListContent: some View {
        VStack(spacing: 16) {
            // Rules list
            ScrollView {
                GlassEffectContainer {
                    LazyVStack(spacing: 10) {
                        ForEach(ruleStore.rules) { rule in
                            RuleRowView(
                                rule: rule,
                                browser: browserDetector.browser(for: rule.browserID),
                                onToggle: { toggleRule(rule) },
                                onEdit: { editRule(rule) },
                                onDelete: { deleteRule(rule) }
                            )
                        }

                        // Add new rule placeholder
                        AddRulePlaceholder {
                            editingRule = nil
                            isEditing = true
                        }
                    }
                    .padding(8)
                }
            }
            .scrollClipDisabled()

            Divider()

            // Test URL bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    TextField("https://example.com", text: $testURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: .rect(cornerRadius: 10))

                Button("Test") { testURLMatch() }
                    .disabled(testURL.isEmpty || testURL == "https://")

                if let result = testResult {
                    Text(result)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
    }

    private func toggleRule(_ rule: RoutingRule) {
        var updated = rule
        updated.enabled.toggle()
        ruleStore.update(updated)
    }

    private func editRule(_ rule: RoutingRule) {
        editingRule = rule
        isEditing = true
    }

    private func deleteRule(_ rule: RoutingRule) {
        ruleStore.delete(rule)
    }

    private func testURLMatch() {
        guard let url = URL(string: testURL) else {
            testResult = "Invalid URL"
            return
        }
        if let match = URLMatcher.findMatchingRule(url: url, rules: ruleStore.rules) {
            let browserName = browserDetector.browser(for: match.browserID)?.name ?? match.browserID
            testResult = "→ \(browserName)"
        } else {
            testResult = "→ System default"
        }
    }
}

// MARK: - Rule Row

struct RuleRowView: View {
    let rule: RoutingRule
    let browser: Browser?
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Enable/disable toggle
            Button(action: onToggle) {
                Image(systemName: rule.enabled ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(rule.enabled ? .green : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Browser icon
            if let icon = browser?.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "globe")
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
            }

            // Rule info
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.pattern)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(rule.enabled ? .primary : .secondary)

                HStack(spacing: 6) {
                    Text(rule.matchType.displayName)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)

                    Text("→ \(browser?.name ?? "Unknown")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions (visible on hover)
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(.rect(cornerRadius: 12))
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Add Rule Placeholder

struct AddRulePlaceholder: View {
    let onAdd: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onAdd) {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(isHovered ? .accentColor : .secondary.opacity(0.5))

                    Text("Add Rule")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isHovered ? .accentColor : .secondary.opacity(0.6))
                }
                Spacer()
            }
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .foregroundColor(isHovered ? .accentColor.opacity(0.5) : .secondary.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
