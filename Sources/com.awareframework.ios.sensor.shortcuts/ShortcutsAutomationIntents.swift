#if canImport(AppIntents)
import AppIntents
import Foundation

@available(iOS 16.0, macOS 13.0, *)
public struct RecordShortcutAutomationIntent: AppIntent {
    public static var title: LocalizedStringResource = "Record AWARE Automation Event"
    public static var description = IntentDescription(
        "Records a Shortcuts automation event in AWARE.")
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Event")
    public var event: String

    @Parameter(title: "Automation Name")
    public var automationName: String?

    @Parameter(title: "Shortcut Name")
    public var shortcutName: String?

    @Parameter(title: "Trigger")
    public var trigger: String?

    @Parameter(title: "Input")
    public var input: String?

    @Parameter(title: "Value Key")
    public var valueKey: String?

    @Parameter(title: "Value")
    public var value: String?

    @Parameter(title: "Payload")
    public var payload: String?

    public init() {
        self.event = "automation"
        self.automationName = nil
        self.shortcutName = nil
        self.trigger = nil
        self.input = nil
        self.valueKey = nil
        self.value = nil
        self.payload = nil
    }

    public init(
        event: String = "automation",
        automationName: String? = nil,
        shortcutName: String? = nil,
        trigger: String? = nil,
        input: String? = nil,
        valueKey: String? = nil,
        value: String? = nil,
        payload: String? = nil
    ) {
        self.event = event
        self.automationName = automationName
        self.shortcutName = shortcutName
        self.trigger = trigger
        self.input = input
        self.valueKey = valueKey
        self.value = value
        self.payload = payload
    }

    public func perform() async throws -> some IntentResult {
        ShortcutsAutomationSensor.recordAutomationEvent(
            event: event,
            shortcutName: shortcutName ?? "",
            automationName: automationName ?? "",
            trigger: trigger ?? "",
            input: input ?? "",
            valueKey: valueKey ?? "",
            value: value ?? "",
            payload: payload ?? "",
            source: "app_intent")
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, *)
public struct ShortcutsAutomationAppShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordShortcutAutomationIntent(),
            phrases: [
                "Record \(.applicationName) automation event",
                "Log \(.applicationName) automation event",
            ],
            shortTitle: "Record Automation",
            systemImageName: "gearshape.2")
    }
}

@available(iOS 16.0, macOS 13.0, *)
public struct ShortcutsAutomationAppIntentsPackage: AppIntentsPackage {}
#endif
