import Foundation
import OSLog

/// Product analytics event with deliberately low-cardinality, non-personal
/// properties. Never add template names, task text, calendar data, or errors
/// containing user content here.
struct AnalyticsEvent: Equatable {
    enum Name: String {
        case appOpened = "app_opened"
        case onboardingCompleted = "onboarding_completed"
        case templateOpened = "template_opened"
        case customTemplateCreated = "custom_template_created"
        case exportStarted = "export_started"
        case exportCompleted = "export_completed"
        case exportFailed = "export_failed"
        case paywallViewed = "paywall_viewed"
        case purchaseStarted = "purchase_started"
        case purchaseCompleted = "purchase_completed"
        case purchaseNotCompleted = "purchase_not_completed"
        case purchaseFailed = "purchase_failed"
        case restoreStarted = "restore_started"
        case restoreCompleted = "restore_completed"
        case restoreNoPurchases = "restore_no_purchases"
        case restoreFailed = "restore_failed"
        case remindersSourceChanged = "reminders_source_changed"
        case remindersPermissionResult = "reminders_permission_result"
        case templateShareOpened = "template_share_opened"
        case templateImported = "template_imported"
        case templateImportFailed = "template_import_failed"
    }

    let name: Name
    let properties: [String: String]
}

protocol AnalyticsSink {
    func send(_ event: AnalyticsEvent)
}

private struct NoOpAnalyticsSink: AnalyticsSink {
    func send(_ event: AnalyticsEvent) {}
}

private struct CompositeAnalyticsSink: AnalyticsSink {
    let sinks: [any AnalyticsSink]

    func send(_ event: AnalyticsEvent) {
        for sink in sinks {
            sink.send(event)
        }
    }
}

#if DEBUG
private struct DebugAnalyticsSink: AnalyticsSink {
    private let logger = Logger(
        subsystem: "com.lockscreenstudio.app",
        category: "ProductAnalytics"
    )

    func send(_ event: AnalyticsEvent) {
        logger.debug(
            "Event \(event.name.rawValue, privacy: .public) \(String(describing: event.properties), privacy: .public)"
        )
    }
}
#endif

/// Vendor-neutral analytics facade. No network provider is currently attached:
/// Release builds discard events, while Debug builds log them locally. Keeping
/// event instrumentation dormant lets us add an explicitly consented provider
/// later without changing product flows now.
@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var sink: any AnalyticsSink

    init(sink: (any AnalyticsSink)? = nil) {
        if let sink {
            self.sink = sink
        } else {
            #if DEBUG
            self.sink = CompositeAnalyticsSink(sinks: [DebugAnalyticsSink()])
            #else
            self.sink = NoOpAnalyticsSink()
            #endif
        }
    }

    func track(
        _ name: AnalyticsEvent.Name,
        properties: [String: String] = [:]
    ) {
        sink.send(AnalyticsEvent(name: name, properties: properties))
    }

    static func templateProperties(_ template: WallpaperTemplate) -> [String: String] {
        let isCanonicalBuiltIn = template.builtInKey != nil
        return [
            "template_key": template.builtInKey ?? "custom",
            "template_type": isCanonicalBuiltIn ? "built_in" : "custom",
            "template_pro": String(template.isPro),
        ]
    }

    static func remindersProperties(for panels: [PanelConfiguration]) -> [String: String] {
        let usesAppleReminders = panels.contains { panel in
            guard panel.panelType == .todo,
                  panel.isVisible,
                  let config = panel.decodeConfig(TodoConfig.self) else {
                return false
            }
            return config.source.usesAppleReminders
        }

        return ["uses_apple_reminders": String(usesAppleReminders)]
    }

}
