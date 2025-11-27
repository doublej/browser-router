import Foundation

final class RuleStore: ObservableObject {
    @Published var rules: [RoutingRule] = []
    @Published var routingEnabled: Bool = true
    @Published var notificationSettings = NotificationSettings()
    @Published var recentRoutes: [RecentRoute] = []
    @Published var fallbackBrowserID: String?

    private let rulesKey = "BrowserRouter.rules"
    private let enabledKey = "BrowserRouter.enabled"
    private let notifKey = "BrowserRouter.notifications"
    private let recentKey = "BrowserRouter.recent"
    private let fallbackKey = "BrowserRouter.fallbackBrowser"

    init() {
        load()
    }

    func load() {
        routingEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        if UserDefaults.standard.object(forKey: enabledKey) == nil {
            routingEnabled = true
        }

        let decoder = JSONDecoder()

        if let data = UserDefaults.standard.data(forKey: rulesKey) {
            rules = (try? decoder.decode([RoutingRule].self, from: data)) ?? []
            rules.sort { $0.priority < $1.priority }
        }

        if let data = UserDefaults.standard.data(forKey: notifKey) {
            notificationSettings = (try? decoder.decode(NotificationSettings.self, from: data)) ?? NotificationSettings()
        }

        if let data = UserDefaults.standard.data(forKey: recentKey) {
            recentRoutes = (try? decoder.decode([RecentRoute].self, from: data)) ?? []
        }

        fallbackBrowserID = UserDefaults.standard.string(forKey: fallbackKey)
    }

    func save() {
        UserDefaults.standard.set(routingEnabled, forKey: enabledKey)
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(rules) {
            UserDefaults.standard.set(data, forKey: rulesKey)
        }
        if let data = try? encoder.encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: notifKey)
        }
        if let fallbackID = fallbackBrowserID {
            UserDefaults.standard.set(fallbackID, forKey: fallbackKey)
        } else {
            UserDefaults.standard.removeObject(forKey: fallbackKey)
        }
    }

    func setFallbackBrowser(_ browserID: String?) {
        fallbackBrowserID = browserID
        save()
    }

    func addRecentRoute(_ route: RecentRoute) {
        recentRoutes.insert(route, at: 0)
        if recentRoutes.count > notificationSettings.maxRecentURLs {
            recentRoutes = Array(recentRoutes.prefix(notificationSettings.maxRecentURLs))
        }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(recentRoutes) {
            UserDefaults.standard.set(data, forKey: recentKey)
        }
    }

    func clearRecentRoutes() {
        recentRoutes.removeAll()
        UserDefaults.standard.removeObject(forKey: recentKey)
    }

    func add(_ rule: RoutingRule) {
        var newRule = rule
        newRule.priority = (rules.map(\.priority).max() ?? -1) + 1
        rules.append(newRule)
        save()
    }

    func update(_ rule: RoutingRule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index] = rule
        save()
    }

    func delete(_ rule: RoutingRule) {
        rules.removeAll { $0.id == rule.id }
        reindex()
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        reindex()
        save()
    }

    private func reindex() {
        for i in rules.indices {
            rules[i].priority = i
        }
    }

    func toggleEnabled() {
        routingEnabled.toggle()
        save()
    }
}
