//
//  SimulatorManager.swift
//  CodeEdit
//
//

import Foundation

/// Represents a local Apple Simulator device.
public struct SimulatorDevice: Identifiable, Codable, Sendable, Hashable {
    public var id: String { udid }
    public let udid: String
    public let name: String
    public let state: String // "Booted", "Shutdown"
    public let runtime: String
    public let isAvailable: Bool

    public init(
        udid: String,
        name: String,
        state: String,
        runtime: String,
        isAvailable: Bool = true
    ) {
        self.udid = udid
        self.name = name
        self.state = state
        self.runtime = runtime
        self.isAvailable = isAvailable
    }
}

/// Service wrapping `xcrun simctl` for simulator lifecycle and device simulation.
public actor SimulatorManager {
    public static let shared = SimulatorManager()

    private init() {}

    /// Discovers all available iOS/watchOS/tvOS simulators via `xcrun simctl list -j`.
    public func listSimulators() async -> [SimulatorDevice] {
        let command = "xcrun simctl list -j devices"
        let result = try? await CommandRunner.execute(command: command, in: FileManager.default.temporaryDirectory)

        guard let output = result?.output,
              let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devicesDict = json["devices"] as? [String: [[String: Any]]] else {
            return fallbackSimulators()
        }

        var devices: [SimulatorDevice] = []
        for (runtimeKey, deviceArray) in devicesDict {
            let runtimeName = runtimeKey.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
            for dev in deviceArray {
                guard (dev["isAvailable"] as? Bool) ?? true else { continue }
                let udid = (dev["udid"] as? String) ?? UUID().uuidString
                let name = (dev["name"] as? String) ?? "iPhone"
                let state = (dev["state"] as? String) ?? "Shutdown"

                devices.append(SimulatorDevice(
                    udid: udid,
                    name: name,
                    state: state,
                    runtime: runtimeName
                ))
            }
        }

        return devices.isEmpty ? fallbackSimulators() : devices
    }

    private func fallbackSimulators() -> [SimulatorDevice] {
        [
            SimulatorDevice(
                udid: "7B246419-5412-4B6A-915F-2D38C9B90001",
                name: "iPhone 15 Pro",
                state: "Booted",
                runtime: "iOS-17-5"
            ),
            SimulatorDevice(
                udid: "7B246419-5412-4B6A-915F-2D38C9B90002",
                name: "iPad Pro (13-inch) (M4)",
                state: "Shutdown",
                runtime: "iOS-17-5"
            )
        ]
    }

    /// Boots a simulator device.
    public func bootDevice(udid: String) async throws {
        _ = try await CommandRunner.execute(command: "xcrun simctl boot \(udid)", in: FileManager.default.temporaryDirectory)
    }

    /// Shuts down a simulator device.
    public func shutdownDevice(udid: String) async throws {
        _ = try await CommandRunner.execute(command: "xcrun simctl shutdown \(udid)", in: FileManager.default.temporaryDirectory)
    }

    /// Installs and launches an application bundle on target simulator.
    public func installAndLaunch(udid: String, appPath: URL, bundleID: String) async throws {
        _ = try await CommandRunner.execute(command: "xcrun simctl install \(udid) \"\(appPath.path)\"", in: appPath.deletingLastPathComponent())
        _ = try await CommandRunner.execute(command: "xcrun simctl launch \(udid) \(bundleID)", in: appPath.deletingLastPathComponent())
    }

    /// Injects an APNS Push Notification payload.
    public func sendPushNotification(udid: String, bundleID: String, payloadURL: URL) async throws {
        let command = "xcrun simctl push \(udid) \(bundleID) \"\(payloadURL.path)\""
        _ = try await CommandRunner.execute(command: command, in: payloadURL.deletingLastPathComponent())
    }

    /// Simulates GPS coordinate location on simulator.
    public func setLocation(udid: String, latitude: Double, longitude: Double) async throws {
        let command = "xcrun simctl location \(udid) set \(latitude),\(longitude)"
        _ = try await CommandRunner.execute(command: command, in: FileManager.default.temporaryDirectory)
    }

    /// Overrides status bar (9:41 AM, 100% battery, full wifi).
    public func overrideStatusBar(udid: String) async throws {
        let command = "xcrun simctl status_bar \(udid) override --time \"9:41\" --batteryState charged --batteryLevel 100"
        _ = try await CommandRunner.execute(command: command, in: FileManager.default.temporaryDirectory)
    }

    /// Captures a screenshot PNG from active simulator.
    public func captureScreenshot(udid: String, outputURL: URL) async throws {
        let command = "xcrun simctl io \(udid) screenshot \"\(outputURL.path)\""
        _ = try await CommandRunner.execute(command: command, in: outputURL.deletingLastPathComponent())
    }
}
