import Foundation
import com_awareframework_ios_core

extension Notification.Name {
    public static let actionAwareShortcutsAutomation =
        Notification.Name(ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION)
    public static let actionAwareShortcutsAutomationStart =
        Notification.Name(ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_START)
    public static let actionAwareShortcutsAutomationStop =
        Notification.Name(ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_STOP)
    public static let actionAwareShortcutsAutomationSync =
        Notification.Name(ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_SYNC)
    public static let actionAwareShortcutsAutomationSetLabel =
        Notification.Name(ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_SET_LABEL)
    public static let actionAwareShortcutsAutomationSyncCompletion =
        Notification.Name(ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_SYNC_COMPLETION)
    public static let actionAwareShortcutsAutomationEvent =
        Notification.Name(ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_EVENT)
}

public protocol ShortcutsAutomationObserver {
    func onShortcutAutomationEvent(data: ShortcutAutomationEventData)
}

public extension ShortcutsAutomationObserver {
    func onShortcutAutomationEvent(data: ShortcutAutomationEventData) {}
}

public class ShortcutsAutomationSensor: AwareSensor {

    public static let TAG = "AWARE::ShortcutsAutomation"

    public static let ACTION_AWARE_SHORTCUTS_AUTOMATION =
        "com.awareframework.ios.sensor.shortcuts.automation"
    public static let ACTION_AWARE_SHORTCUTS_AUTOMATION_START =
        "com.awareframework.ios.sensor.shortcuts.automation.SENSOR_START"
    public static let ACTION_AWARE_SHORTCUTS_AUTOMATION_STOP =
        "com.awareframework.ios.sensor.shortcuts.automation.SENSOR_STOP"
    public static let ACTION_AWARE_SHORTCUTS_AUTOMATION_SET_LABEL =
        "com.awareframework.ios.sensor.shortcuts.automation.SET_LABEL"
    public static let ACTION_AWARE_SHORTCUTS_AUTOMATION_SYNC =
        "com.awareframework.ios.sensor.shortcuts.automation.SENSOR_SYNC"
    public static let ACTION_AWARE_SHORTCUTS_AUTOMATION_SYNC_COMPLETION =
        "com.awareframework.ios.sensor.shortcuts.automation.SENSOR_SYNC_COMPLETION"
    public static let ACTION_AWARE_SHORTCUTS_AUTOMATION_EVENT =
        "com.awareframework.ios.sensor.shortcuts.automation.EVENT"

    public static let EXTRA_DATA = "data"
    public static let EXTRA_LABEL = "label"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"

    public static weak var shared: ShortcutsAutomationSensor?
    private static var fallbackSensor: ShortcutsAutomationSensor?

    public var CONFIG = Config()

    public class Config: SensorConfig {
        public var sensorObserver: ShortcutsAutomationObserver?

        public override init() {
            super.init()
            dbPath = "aware_shortcuts_automation"
        }

        public func apply(closure: (_ config: ShortcutsAutomationSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }

    public override convenience init() {
        self.init(ShortcutsAutomationSensor.Config())
    }

    public init(_ config: ShortcutsAutomationSensor.Config) {
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
        super.syncConfig = DbSyncConfig().apply { syncConfig in
            syncConfig.debug = config.debug
            syncConfig.dispatchQueue = DispatchQueue(
                label: "com.awareframework.ios.sensor.shortcuts.automation.sync.queue")
            syncConfig.completionHandler = { status, error in
                var userInfo: [String: Any] = [
                    ShortcutsAutomationSensor.EXTRA_STATUS: status,
                    "tableName": ShortcutAutomationEventData.databaseTableName,
                    "objectType": ShortcutAutomationEventData.self,
                ]
                if let error = error {
                    userInfo[ShortcutsAutomationSensor.EXTRA_ERROR] = error
                }
                self.notificationCenter.post(
                    name: .actionAwareShortcutsAutomationSyncCompletion,
                    object: self,
                    userInfo: userInfo)
            }
        }
        initializeTable()
        ShortcutsAutomationSensor.shared = self
    }

    public override func start() {
        notificationCenter.post(name: .actionAwareShortcutsAutomationStart, object: self)
        if CONFIG.debug { print(ShortcutsAutomationSensor.TAG, "started") }
    }

    public override func stop() {
        notificationCenter.post(name: .actionAwareShortcutsAutomationStop, object: self)
        if CONFIG.debug { print(ShortcutsAutomationSensor.TAG, "stopped") }
    }

    public override func sync(force: Bool = false) {
        guard let engine = self.dbEngine, let syncConfig = self.syncConfig else { return }
        syncConfig.debug = self.CONFIG.debug
        engine.startSync(syncConfig)
        notificationCenter.post(name: .actionAwareShortcutsAutomationSync, object: self)
    }

    public override func set(label: String) {
        CONFIG.label = label
        notificationCenter.post(
            name: .actionAwareShortcutsAutomationSetLabel,
            object: self,
            userInfo: [ShortcutsAutomationSensor.EXTRA_LABEL: label])
    }

    @discardableResult
    public func recordAutomationEvent(
        event: String = "automation",
        shortcutName: String = "",
        automationName: String = "",
        trigger: String = "",
        input: String = "",
        valueKey: String = "",
        value: String = "",
        payload: String = "",
        source: String = "app_intent"
    ) -> ShortcutAutomationEventData {
        var data = ShortcutAutomationEventData(
            event: event,
            shortcutName: shortcutName,
            automationName: automationName,
            trigger: trigger,
            source: source,
            input: input,
            valueKey: valueKey,
            value: value,
            payload: payload,
            label: CONFIG.label)
        data.deviceId = AwareUtils.getCommonDeviceId()
        saveModel(data)

        CONFIG.sensorObserver?.onShortcutAutomationEvent(data: data)
        notificationCenter.post(
            name: .actionAwareShortcutsAutomationEvent,
            object: self,
            userInfo: [ShortcutsAutomationSensor.EXTRA_DATA: data])
        notificationCenter.post(name: .actionAwareShortcutsAutomation, object: self)
        return data
    }

    @discardableResult
    public static func recordAutomationEvent(
        event: String = "automation",
        shortcutName: String = "",
        automationName: String = "",
        trigger: String = "",
        input: String = "",
        valueKey: String = "",
        value: String = "",
        payload: String = "",
        source: String = "app_intent"
    ) -> ShortcutAutomationEventData {
        let sensor = shared ?? defaultFallbackSensor()
        return sensor.recordAutomationEvent(
            event: event,
            shortcutName: shortcutName,
            automationName: automationName,
            trigger: trigger,
            input: input,
            valueKey: valueKey,
            value: value,
            payload: payload,
            source: source)
    }

    @discardableResult
    public func handle(url: URL) -> ShortcutAutomationEventData {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = Self.queryDictionary(from: components?.queryItems ?? [])
        let payload = Self.jsonString(from: query)
        return recordAutomationEvent(
            event: query["event"] ?? components?.host ?? "automation",
            shortcutName: query["shortcutName"] ?? query["shortcut"] ?? "",
            automationName: query["automationName"] ?? query["automation"] ?? "",
            trigger: query["trigger"] ?? "",
            input: query["input"] ?? "",
            valueKey: query["valueKey"] ?? query["key"] ?? "",
            value: query["value"] ?? "",
            payload: payload,
            source: "url")
    }

    @discardableResult
    public func handle(userActivity: NSUserActivity) -> ShortcutAutomationEventData {
        let payload = Self.jsonString(from: userActivity.userInfo ?? [:])
        return recordAutomationEvent(
            event: userActivity.activityType,
            shortcutName: userActivity.title ?? "",
            payload: payload,
            source: "user_activity")
    }

    private func initializeTable() {
        guard let queue = (self.dbEngine as? SQLiteEngine)?.getSQLiteInstance() else { return }
        do {
            try ShortcutAutomationEventData.createTable(queue: queue)
        } catch {
            if CONFIG.debug { print(ShortcutsAutomationSensor.TAG, error) }
        }
    }

    private func saveModel(_ model: ShortcutAutomationEventData) {
        guard let engine = self.dbEngine as? SQLiteEngine else { return }
        engine.save([model])
    }

    private static func defaultFallbackSensor() -> ShortcutsAutomationSensor {
        if let fallbackSensor {
            return fallbackSensor
        }
        let sensor = ShortcutsAutomationSensor()
        fallbackSensor = sensor
        return sensor
    }

    private static func queryDictionary(from items: [URLQueryItem]) -> [String: String] {
        var dictionary: [String: String] = [:]
        items.forEach { item in
            dictionary[item.name] = item.value ?? ""
        }
        return dictionary
    }

    private static func jsonString(from dictionary: [AnyHashable: Any]) -> String {
        var stringDictionary: [String: Any] = [:]
        dictionary.forEach { key, value in
            stringDictionary[String(describing: key)] = value
        }
        return jsonString(from: stringDictionary)
    }

    private static func jsonString(from dictionary: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(dictionary),
            let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys]),
            let string = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return string
    }
}
