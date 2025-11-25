import SwiftUI

struct RuleListView: View {
    @EnvironmentObject var ruleStore: RuleStore
    @EnvironmentObject var browserDetector: BrowserDetector
    @State private var selectedRule: RoutingRule?
    @State private var editingRule: RoutingRule?
    @State private var isEditing = false
    @State private var testURL = ""
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
    }

    private var ruleListContent: some View {
        VStack(spacing: 16) {
            List(selection: $selectedRule) {
                ForEach(ruleStore.rules) { rule in
                    RuleRowView(rule: rule, browserName: browserName(for: rule.browserID))
                        .tag(rule)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRule = rule
                        }
                        .onTapGesture(count: 2) {
                            editingRule = rule
                            isEditing = true
                        }
                }
                .onMove { source, destination in
                    ruleStore.move(from: source, to: destination)
                }
            }
            .listStyle(.inset)

            HStack {
                TextField("Test URL", text: $testURL)
                    .textFieldStyle(.roundedBorder)

                Button("Test") { testURLMatch() }
                    .disabled(testURL.isEmpty)

                if let result = testResult {
                    Text(result)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: { editingRule = nil; isEditing = true }) {
                    Image(systemName: "plus")
                }

                Button(action: editSelected) {
                    Image(systemName: "pencil")
                }
                .disabled(selectedRule == nil)

                Button(action: deleteSelected) {
                    Image(systemName: "trash")
                }
                .disabled(selectedRule == nil)
            }
        }
    }

    private func browserName(for id: String) -> String {
        browserDetector.browser(for: id)?.name ?? id
    }

    private func editSelected() {
        editingRule = selectedRule
        isEditing = true
    }

    private func deleteSelected() {
        guard let rule = selectedRule else { return }
        ruleStore.delete(rule)
        selectedRule = nil
    }

    private func testURLMatch() {
        guard let url = URL(string: testURL) else {
            testResult = "Invalid URL"
            return
        }
        if let match = URLMatcher.findMatchingRule(url: url, rules: ruleStore.rules) {
            testResult = "→ \(browserName(for: match.browserID))"
        } else {
            testResult = "→ System default"
        }
    }
}

struct RuleRowView: View {
    let rule: RoutingRule
    let browserName: String

    var body: some View {
        HStack {
            Image(systemName: rule.enabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(rule.enabled ? .green : .secondary)

            VStack(alignment: .leading) {
                Text(rule.pattern)
                    .font(.body)
                Text(rule.matchType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(browserName)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
