import Foundation
import GRDB
import com_awareframework_ios_core

public struct ShortcutAutomationEventData: BaseDbModelSQLite {
    public static let databaseTableName = "ios_shortcuts_automation"
    public static let TABLE_NAME = databaseTableName

    public var id: Int64?
    public var timestamp: Int64
    public var deviceId: String = AwareUtils.getCommonDeviceId()
    public var label: String = ""
    public var timezone: Int = AwareUtils.getTimeZone()
    public var os: String = "iOS"
    public var jsonVersion: Int = 1

    public var event: String = ""
    public var shortcutName: String = ""
    public var automationName: String = ""
    public var trigger: String = ""
    public var source: String = ""
    public var input: String = ""
    public var valueKey: String = ""
    public var value: String = ""
    public var payload: String = ""
    public var bundleIdentifier: String = ""

    public init(
        event: String = "",
        shortcutName: String = "",
        automationName: String = "",
        trigger: String = "",
        source: String = "",
        input: String = "",
        valueKey: String = "",
        value: String = "",
        payload: String = "",
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "",
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        label: String = ""
    ) {
        self.timestamp = timestamp
        self.label = label
        self.event = event
        self.shortcutName = shortcutName
        self.automationName = automationName
        self.trigger = trigger
        self.source = source
        self.input = input
        self.valueKey = valueKey
        self.value = value
        self.payload = payload
        self.bundleIdentifier = bundleIdentifier
    }

    public init(_ dict: [String: Any]) {
        self.id = dict["id"] as? Int64
        self.timestamp = dict["timestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.deviceId = dict["deviceId"] as? String ?? AwareUtils.getCommonDeviceId()
        self.label = dict["label"] as? String ?? ""
        self.timezone = dict["timezone"] as? Int ?? AwareUtils.getTimeZone()
        self.os = dict["os"] as? String ?? "iOS"
        self.jsonVersion = dict["jsonVersion"] as? Int ?? 1
        self.event = dict["event"] as? String ?? ""
        self.shortcutName = dict["shortcutName"] as? String ?? ""
        self.automationName = dict["automationName"] as? String ?? ""
        self.trigger = dict["trigger"] as? String ?? ""
        self.source = dict["source"] as? String ?? ""
        self.input = dict["input"] as? String ?? ""
        self.valueKey = dict["valueKey"] as? String ?? ""
        self.value = dict["value"] as? String ?? ""
        self.payload = dict["payload"] as? String ?? ""
        self.bundleIdentifier = dict["bundleIdentifier"] as? String ?? ""
    }

    public func toDictionary() -> [String: Any] {
        [
            "id": id ?? -1,
            "timestamp": timestamp,
            "deviceId": deviceId,
            "label": label,
            "timezone": timezone,
            "os": os,
            "jsonVersion": jsonVersion,
            "event": event,
            "shortcutName": shortcutName,
            "automationName": automationName,
            "trigger": trigger,
            "source": source,
            "input": input,
            "valueKey": valueKey,
            "value": value,
            "payload": payload,
            "bundleIdentifier": bundleIdentifier,
        ]
    }

    public static func createTable(queue: DatabaseQueue) throws {
        try queue.write { db in
            try db.create(table: databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("timestamp", .integer).notNull()
                t.column("deviceId", .text).notNull()
                t.column("label", .text)
                t.column("timezone", .integer).notNull()
                t.column("os", .text).notNull()
                t.column("jsonVersion", .integer).notNull()
                t.column("event", .text).notNull()
                t.column("shortcutName", .text).notNull()
                t.column("automationName", .text).notNull()
                t.column("trigger", .text).notNull()
                t.column("source", .text).notNull()
                t.column("input", .text).notNull()
                t.column("valueKey", .text).notNull()
                t.column("value", .text).notNull()
                t.column("payload", .text).notNull()
                t.column("bundleIdentifier", .text).notNull()
            }
            try addColumnIfNeeded(db: db, tableName: databaseTableName, columnName: "valueKey")
            try addColumnIfNeeded(db: db, tableName: databaseTableName, columnName: "value")
        }
    }

    private static func addColumnIfNeeded(
        db: Database,
        tableName: String,
        columnName: String
    ) throws {
        let existingColumns = try db.columns(in: tableName).map(\.name)
        guard existingColumns.contains(columnName) == false else { return }
        try db.execute(sql: "ALTER TABLE \(tableName) ADD COLUMN \(columnName) TEXT NOT NULL DEFAULT ''")
    }
}
