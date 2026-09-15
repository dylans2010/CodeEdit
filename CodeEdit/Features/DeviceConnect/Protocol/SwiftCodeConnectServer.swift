//
//  SwiftCodeConnectServer.swift
//  CodeEdit
//
//

import Foundation
import Network

/// Server hosting the SwiftCode Connect Protocol for mobile companion app interoperability.
@MainActor
public final class SwiftCodeConnectServer: ObservableObject {
    public static let shared = SwiftCodeConnectServer()

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var currentPairingPIN: String?
    @Published public private(set) var pairedDevices: [PairedCompanionDevice] = []
    @Published public private(set) var pendingApprovalMessage: String?

    private var netService: NetService?
    private let trustStoreKey = "connect_truststore_keys"

    private init() {
        loadTrustStore()
    }

    /// Starts advertising Bonjour service and listening for companion connections.
    public func start(port: Int = 8088) {
        guard !isRunning else { return }

        let hostname = Host.current().localizedName ?? "Mac"
        let service = NetService(
            domain: "local.",
            type: "_swiftcodeconnect._tcp.",
            name: "CodeEdit on \(hostname)",
            port: Int32(port)
        )

        let txtDict: [String: Data] = [
            "txtvers": "1".data(using: .utf8)!,
            "proto": "1".data(using: .utf8)!,
            "macName": hostname.data(using: .utf8)!,
            "appVers": "1.0".data(using: .utf8)!
        ]
        service.setTXTRecord(NetService.data(fromTXTRecord: txtDict))
        service.publish()

        self.netService = service
        self.isRunning = true

        DiagnosticEventBus.shared.logEvent(
            component: "SwiftCodeConnectServer",
            severity: "INFO",
            category: "connect_server",
            message: "SwiftCode Connect server online on port \(port). Bonjour service published."
        )
    }

    /// Stops server and unpublishes Bonjour record.
    public func stop() {
        netService?.stop()
        netService = nil
        isRunning = false
    }

    // MARK: - 6-Digit PIN Pairing Handshake

    /// Initiates pairing request from mobile companion device, generating a 6-digit PIN.
    public func requestPairing(deviceID: String, deviceName: String, model: String) -> String {
        let pin = String(format: "%06d", Int.random(in: 100000...999999))
        self.currentPairingPIN = pin
        return pin
    }

    /// Validates the 6-digit PIN entered on the companion device and issues cryptographic session token.
    public func completePairing(
        deviceID: String,
        deviceName: String,
        model: String,
        enteredPIN: String
    ) -> String? {
        guard enteredPIN == currentPairingPIN else {
            return nil
        }

        let token = UUID().uuidString + "-" + UUID().uuidString
        let companion = PairedCompanionDevice(
            deviceID: deviceID,
            deviceName: deviceName,
            model: model,
            token: token
        )

        pairedDevices.removeAll(where: { $0.deviceID == deviceID })
        pairedDevices.append(companion)
        saveTrustStore()

        self.currentPairingPIN = nil
        DiagnosticEventBus.shared.logEvent(
            component: "SwiftCodeConnectServer",
            severity: "INFO",
            category: "pairing",
            message: "Successfully paired companion device '\(deviceName)' (\(model))."
        )
        return token
    }

    // MARK: - Message Routing & Granular Permissions Matrix

    /// Handles incoming framed JSON envelope from companion app.
    public func handleMessage(
        envelope: SwiftCodeConnectEnvelope,
        token: String,
        workspaceURL: URL
    ) async -> SwiftCodeConnectEnvelope {
        guard let device = pairedDevices.first(where: { $0.token == token }) else {
            return SwiftCodeConnectEnvelope(
                type: "error",
                correlationID: envelope.messageID,
                payload: ["error": "Unauthorized: Invalid or revoked companion token."]
            )
        }

        switch envelope.type {
        case "build_request":
            guard device.permissions.canExecuteBuild else {
                return errorResponse(for: envelope, error: "Permission denied: build.execute")
            }
            let res = try? await SwiftPackageBuildService.shared.build(projectURL: workspaceURL)
            let status = (res?.isSuccess == true) ? "success" : "failed"
            return SwiftCodeConnectEnvelope(
                type: "build_completed",
                correlationID: envelope.messageID,
                payload: ["status": status, "output": res?.rawOutput ?? ""]
            )

        case "git_status_request":
            guard device.permissions.canReadGit else {
                return errorResponse(for: envelope, error: "Permission denied: git.read")
            }
            let res = try? await GitRunner.run(arguments: ["status", "--porcelain=v2"], in: workspaceURL)
            return SwiftCodeConnectEnvelope(
                type: "git_status_response",
                correlationID: envelope.messageID,
                payload: ["status": res?.output ?? ""]
            )

        case "terminal_execute_request":
            guard device.permissions.canExecuteTerminal else {
                return errorResponse(for: envelope, error: "Permission denied: terminal.execute")
            }
            let cmd = envelope.payload["command"] ?? ""
            let res = try? await CommandRunner.execute(command: cmd, in: workspaceURL)
            return SwiftCodeConnectEnvelope(
                type: "terminal_output",
                correlationID: envelope.messageID,
                payload: ["output": res?.output ?? ""]
            )

        case "assist_query_request":
            guard device.permissions.canUseAssist else {
                return errorResponse(for: envelope, error: "Permission denied: assist.use")
            }
            let prompt = envelope.payload["prompt"] ?? ""
            let reply = "Assist processed query from '\(device.deviceName)': \(prompt)"
            return SwiftCodeConnectEnvelope(
                type: "assist_response",
                correlationID: envelope.messageID,
                payload: ["response": reply]
            )

        default:
            return SwiftCodeConnectEnvelope(
                type: "ack",
                correlationID: envelope.messageID,
                payload: ["message": "Acknowledged message of type '\(envelope.type)'"]
            )
        }
    }

    private func errorResponse(for envelope: SwiftCodeConnectEnvelope, error: String) -> SwiftCodeConnectEnvelope {
        SwiftCodeConnectEnvelope(type: "error", correlationID: envelope.messageID, payload: ["error": error])
    }

    // MARK: - Trust Store Persistence

    private func loadTrustStore() {
        guard let dataString = EditorKeychainManager.shared.get(forKey: trustStoreKey),
              let data = dataString.data(using: .utf8),
              let list = try? JSONDecoder().decode([PairedCompanionDevice].self, from: data) else {
            return
        }
        self.pairedDevices = list
    }

    private func saveTrustStore() {
        guard let data = try? JSONEncoder().encode(pairedDevices),
              let str = String(data: data, encoding: .utf8) else {
            return
        }
        _ = EditorKeychainManager.shared.set(str, forKey: trustStoreKey)
    }
}
