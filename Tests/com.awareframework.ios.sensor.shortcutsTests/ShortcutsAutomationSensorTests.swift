import XCTest
@testable import com_awareframework_ios_sensor_shortcuts

final class ShortcutsAutomationSensorTests: XCTestCase {

    func testDefaultConfig() {
        let config = ShortcutsAutomationSensor.Config()
        XCTAssertEqual(config.dbPath, "aware_shortcuts_automation")
        XCTAssertNil(config.sensorObserver)
    }

    func testConfigApply() {
        let config = ShortcutsAutomationSensor.Config().apply { c in
            c.debug = true
            c.label = "study"
        }
        XCTAssertTrue(config.debug)
        XCTAssertEqual(config.label, "study")
    }

    func testDataInitFromDictionary() {
        let data = ShortcutAutomationEventData([
            "timestamp": Int64(1000),
            "event": "arrive",
            "shortcutName": "Morning",
            "automationName": "Arrive Home",
            "trigger": "location",
            "source": "app_intent",
            "input": "home",
            "valueKey": "soundName",
            "value": "baby_crying",
            "payload": "{\"key\":\"value\"}",
            "bundleIdentifier": "com.example.app",
        ])

        XCTAssertEqual(data.timestamp, 1000)
        XCTAssertEqual(data.event, "arrive")
        XCTAssertEqual(data.shortcutName, "Morning")
        XCTAssertEqual(data.automationName, "Arrive Home")
        XCTAssertEqual(data.trigger, "location")
        XCTAssertEqual(data.source, "app_intent")
        XCTAssertEqual(data.input, "home")
        XCTAssertEqual(data.valueKey, "soundName")
        XCTAssertEqual(data.value, "baby_crying")
        XCTAssertEqual(data.payload, "{\"key\":\"value\"}")
        XCTAssertEqual(data.bundleIdentifier, "com.example.app")
    }

    func testDataToDictionary() {
        let data = ShortcutAutomationEventData(
            event: "wake",
            shortcutName: "Alarm Shortcut",
            automationName: "Wake Up",
            trigger: "alarm",
            source: "app_intent",
            input: "07:00",
            valueKey: "alarmTime",
            value: "07:00",
            payload: "{\"alarm\":\"07:00\"}",
            timestamp: 2000,
            label: "research")

        let dict = data.toDictionary()
        XCTAssertEqual(dict["timestamp"] as? Int64, 2000)
        XCTAssertEqual(dict["label"] as? String, "research")
        XCTAssertEqual(dict["event"] as? String, "wake")
        XCTAssertEqual(dict["shortcutName"] as? String, "Alarm Shortcut")
        XCTAssertEqual(dict["automationName"] as? String, "Wake Up")
        XCTAssertEqual(dict["trigger"] as? String, "alarm")
        XCTAssertEqual(dict["source"] as? String, "app_intent")
        XCTAssertEqual(dict["input"] as? String, "07:00")
        XCTAssertEqual(dict["valueKey"] as? String, "alarmTime")
        XCTAssertEqual(dict["value"] as? String, "07:00")
        XCTAssertEqual(dict["payload"] as? String, "{\"alarm\":\"07:00\"}")
        XCTAssertEqual(dict["os"] as? String, "iOS")
        XCTAssertEqual(dict["jsonVersion"] as? Int, 1)
    }

    func testSetLabelPostsNotification() {
        let sensor = ShortcutsAutomationSensor()
        let expectation = XCTestExpectation(description: "label notification")
        let observer = NotificationCenter.default.addObserver(
            forName: .actionAwareShortcutsAutomationSetLabel, object: nil, queue: .main
        ) { notification in
            let label = notification.userInfo?[ShortcutsAutomationSensor.EXTRA_LABEL] as? String
            XCTAssertEqual(label, "new-label")
            expectation.fulfill()
        }

        sensor.set(label: "new-label")
        XCTAssertEqual(sensor.CONFIG.label, "new-label")
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testRecordAutomationEventPostsNotification() {
        let sensor = ShortcutsAutomationSensor()
        let expectation = XCTestExpectation(description: "event notification")
        let observer = NotificationCenter.default.addObserver(
            forName: .actionAwareShortcutsAutomationEvent, object: nil, queue: .main
        ) { notification in
            let data = notification.userInfo?[ShortcutsAutomationSensor.EXTRA_DATA]
                as? ShortcutAutomationEventData
            XCTAssertEqual(data?.event, "leave")
            XCTAssertEqual(data?.automationName, "Leave Office")
            expectation.fulfill()
        }

        let data = sensor.recordAutomationEvent(
            event: "leave",
            automationName: "Leave Office",
            trigger: "location",
            valueKey: "place",
            value: "office")

        XCTAssertEqual(data.event, "leave")
        XCTAssertEqual(data.automationName, "Leave Office")
        XCTAssertEqual(data.valueKey, "place")
        XCTAssertEqual(data.value, "office")
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    func testHandleURLMapsQueryItems() {
        let sensor = ShortcutsAutomationSensor()
        let url = URL(
            string: "aware://automation?event=arrive&automationName=Arrive%20Home&shortcutName=Log%20Arrival&trigger=location&input=home&valueKey=soundName&value=baby_crying"
        )!

        let data = sensor.handle(url: url)

        XCTAssertEqual(data.event, "arrive")
        XCTAssertEqual(data.automationName, "Arrive Home")
        XCTAssertEqual(data.shortcutName, "Log Arrival")
        XCTAssertEqual(data.trigger, "location")
        XCTAssertEqual(data.input, "home")
        XCTAssertEqual(data.valueKey, "soundName")
        XCTAssertEqual(data.value, "baby_crying")
        XCTAssertEqual(data.source, "url")
        XCTAssertTrue(data.payload.contains("\"automationName\":\"Arrive Home\""))
        XCTAssertTrue(data.payload.contains("\"value\":\"baby_crying\""))
    }
}
