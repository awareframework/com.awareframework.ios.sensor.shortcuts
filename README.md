# AWARE: Shortcuts Automation

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

This sensor module records events from Apple Shortcuts personal automations. It exposes an App Intent that can be added as an action inside a Shortcuts automation and stores each execution in the AWARE database.

The Shortcuts app does not provide a public API for passively observing every automation on the device. Automations must explicitly call the AWARE action, or call the app through a URL as a fallback.

## Requirements

iOS 14 or later for the sensor. The App Intent action requires iOS 16 or later.

## Installation

1. Open Package Manager Windows
    * Open `Xcode` -> Select `Menu Bar` -> `File` -> `App Package Dependencies...`

2. Find the package using the manager
    * Select `Search Package URL` and type `https://github.com/awareframework/com.awareframework.ios.sensor.shortcuts.git`

3. Import the package into your app target.

```swift
import com_awareframework_ios_sensor_shortcuts
```

## Xcode Setup

### App Intent integration (recommended)

Use this setup when you want the action **Record AWARE Automation Event** to appear in the Shortcuts app.

1. Add this package to the iOS app target.
    * In Xcode, open the app project.
    * Select the app project in the Project navigator.
    * Select the app target.
    * Open **General** -> **Frameworks, Libraries, and Embedded Content**.
    * Confirm `com.awareframework.ios.sensor.shortcuts` is listed.

2. Set the app target deployment version.
    * The sensor can be compiled for iOS 14 or later.
    * The Shortcuts App Intent action requires iOS 16 or later.
    * If you need the Shortcuts action, set **Deployment Target** to iOS 16.0 or later.

3. Import and initialize the sensor from the app.

```swift
import com_awareframework_ios_sensor_shortcuts

let shortcutsAutomationSensor = ShortcutsAutomationSensor(
    ShortcutsAutomationSensor.Config().apply { config in
        config.dbPath = "aware_shortcuts_automation"
        config.dbTableName = ShortcutAutomationEventData.databaseTableName
        config.dbType = .sqlite
    })

shortcutsAutomationSensor.start()
```

4. Build and run the app once on the device.
    * iOS indexes App Intents from installed apps.
    * After installing the app, open the Shortcuts app and search for **Record AWARE Automation Event**.
    * No extra entitlement is required for this App Intent.

If the action does not appear in Shortcuts, confirm that the package product is linked to the app target, clean the build folder, rebuild, and launch the app once.

### URL fallback setup

Use this setup only when you cannot use App Intents.

1. Add a URL scheme to the app target.
    * Select the app target in Xcode.
    * Open **Info** -> **URL Types**.
    * Add a URL scheme such as `aware`.

2. Forward opened URLs to the sensor.

```swift
.onOpenURL { url in
    shortcutsAutomationSensor.handle(url: url)
}
```

3. In Shortcuts, use an **Open URLs** action such as:

```text
aware://automation?event=sound_detected&trigger=sound_recognition&valueKey=soundName&value=baby_crying
```

## Shortcuts Automation Integration

Create and start the sensor in your app:

```swift
let sensor = ShortcutsAutomationSensor(
    ShortcutsAutomationSensor.Config().apply { config in
        config.debug = true
        config.label = "study"
    })
sensor.start()
```

In the Shortcuts app:

1. Open **Automation** and create a personal automation.
2. Choose a trigger, such as time of day, arriving at a location, opening an app, charging, or alarm.
3. Add the app action **Record AWARE Automation Event**.
4. Fill in fields such as `Event`, `Automation Name`, `Shortcut Name`, `Trigger`, `Input`, `Value Key`, `Value`, and `Payload`.

When the automation runs, the action writes one row to `ios_shortcuts_automation`.

## URL Fallback

If App Intents are not available, forward URL opens to the sensor:

```swift
.onOpenURL { url in
    shortcutsAutomationSensor.handle(url: url)
}
```

Then add a Shortcuts **Open URLs** action with a URL such as:

```text
aware://automation?event=arrive&automationName=Arrive%20Home&trigger=location
```

You can pass arbitrary values either as a simple key/value pair:

```text
aware://automation?event=sound_detected&trigger=sound_recognition&valueKey=soundName&value=baby_crying
```

or as JSON in `Payload`:

```json
{"soundName":"baby_crying","confidence":"system","room":"nursery"}
```

## Public Functions

### ShortcutsAutomationSensor

+ `init(_ config: ShortcutsAutomationSensor.Config)`: Initializes the sensor with the given configuration.
+ `start()`: Starts the sensor and posts the start notification.
+ `stop()`: Stops the sensor and posts the stop notification.
+ `sync(force:)`: Syncs stored automation events to the configured host.
+ `set(label:)`: Sets a custom label applied to subsequent events.
+ `recordAutomationEvent(...)`: Stores an automation event directly.
+ `handle(url:)`: Parses a URL from Shortcuts and stores it as an automation event.
+ `handle(userActivity:)`: Stores an `NSUserActivity` as an automation event.

### ShortcutsAutomationSensor.Config

+ `sensorObserver: ShortcutsAutomationObserver?`: Callback for live automation updates.
+ `enabled: Bool`: Sensor is enabled or not. (default = `false`)
+ `debug: Bool`: Enable/disable logging. (default = `false`)
+ `label: String`: Label for the data. (default = `""`)
+ `deviceId: String`: Id of the device associated with the events. (default = `""`)
+ `dbEncryptionKey: String?`: Encryption key for the database. (default = `nil`)
+ `dbType: DatabaseType`: Which db engine to use for saving data. (default = `.none`)
+ `dbPath: String`: Path of the database. (default = `"aware_shortcuts_automation"`)
+ `dbHost: String?`: Host for syncing the database. (default = `nil`)

## Broadcasts

### Fired Broadcasts

+ `ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_EVENT`: fired when an automation event is recorded.
+ `ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_START`: fired when the sensor starts.
+ `ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_STOP`: fired when the sensor stops.
+ `ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_SYNC`: fired when sync starts.
+ `ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_SYNC_COMPLETION`: fired when sync completes.
+ `ShortcutsAutomationSensor.ACTION_AWARE_SHORTCUTS_AUTOMATION_SET_LABEL`: fired when the label changes.

## Data Representation

### ShortcutAutomationEventData

| Field | Type | Description |
| --- | --- | --- |
| event | String | Event name, such as `arrive`, `leave`, `alarm`, or `automation`. |
| shortcutName | String | Name of the shortcut action or shortcut flow. |
| automationName | String | User-visible automation name. |
| trigger | String | Trigger category, such as `time`, `location`, `app`, `battery`, `alarm`, or custom text. |
| source | String | Event source, such as `app_intent`, `url`, `user_activity`, or `manual`. |
| input | String | Optional input value passed from Shortcuts. |
| valueKey | String | Optional custom value key, such as `soundName`. |
| value | String | Optional custom value passed from Shortcuts, such as `baby_crying`. |
| payload | String | Optional JSON or text payload passed from Shortcuts. |
| bundleIdentifier | String | Bundle identifier of the app recording the event. |
| label | String | Customizable label. |
| deviceId | String | AWARE device UUID. |
| timestamp | Int64 | Unixtime milliseconds since 1970. |
| timezone | Int | Timezone of the device. |
| os | String | Operating system of the device (iOS). |
| jsonVersion | Int | JSON schema version. |

## Example Usage

```swift
class Observer: ShortcutsAutomationObserver {
    func onShortcutAutomationEvent(data: ShortcutAutomationEventData) {
        print("Automation:", data.automationName, data.event)
    }
}

let sensor = ShortcutsAutomationSensor(
    ShortcutsAutomationSensor.Config().apply { config in
        config.sensorObserver = Observer()
        config.debug = true
    })

sensor.start()
```

## Author
Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp

## License
Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0.
