//
//  BuiltInDeveloperUtilitiesSuite.swift
//  UniversalIDE
//

import SwiftUI
import Foundation

public struct DevToolDefinition: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let category: String
    public let description: String

    public init(name: String, category: String, description: String) {
        self.name = name
        self.category = category
        self.description = description
    }
}

public final class DeveloperUtilitiesCatalog: @unchecked Sendable {
    public static let shared = DeveloperUtilitiesCatalog()
    public private(set) var tools: [DevToolDefinition] = []

    private init() {
        register156Tools()
    }

    private func register156Tools() {
        // 1. Code & Schema Generators (15 Tools)
        let generators = [
            "JSONToSwiftView", "JSONToTSView", "JSONToPythonView", "JSONToGoView", "JSONToRustView",
            "JSONToKotlinView", "JSONToJavaView", "JSONToCSharpView", "JSONToDartView", "JSONToPHPView",
            "JSONSchemaGeneratorView", "JSONTypeAnalyzerView", "JSONToCSVView", "JSONToTOMLView", "QRCodeGeneratorView"
        ]
        for g in generators { tools.append(DevToolDefinition(name: g, category: "Generators", description: "Generator tool \(g)")) }

        // 2. Format Converters & Parsers (18 Tools)
        let converters = [
            "YAMLToJSONView", "JSONFormatterView", "YAMLConverterView", "TOMLToJSONView", "CSVToJSONView",
            "CSVParserDevToolView", "XMLToJSONView", "XMLFormatterView", "SQLFormatterView", "Base64ConverterView",
            "Base64FileConverterView", "Base64ImageDecoderView", "Base32ConverterDevToolView", "BinaryConverterView",
            "BinaryHexConverterDevToolView", "HexDecimalConverterView", "ASCIIHexConverterDevToolView", "EpochConverterDevToolView"
        ]
        for c in converters { tools.append(DevToolDefinition(name: c, category: "Converters", description: "Converter tool \(c)")) }

        // 3. Cryptography & Security (15 Tools)
        let crypto = [
            "AESEncryptionDevToolView", "RSAKeyGeneratorView", "HashGeneratorView", "HMACGeneratorView", "BcryptHashGeneratorView",
            "JWTDecoderView", "PasswordGeneratorView", "PasswordStrengthMeterView", "CSRFTokenDevToolView", "CertificateDecoderView",
            "SSLCheckerView", "AppReceiptInspectorDevToolView", "BiometricAuthSimDevToolView", "EncryptionToolDevToolView", "UnixPermissionsCalculatorView"
        ]
        for cr in crypto { tools.append(DevToolDefinition(name: cr, category: "Cryptography", description: "Crypto tool \(cr)")) }

        // 4. Text & String Utilities (16 Tools)
        let textTools = [
            "CaseConverterView", "TextCaseSwapperView", "CharacterEscaperDevToolView", "JSONStringEscaperView", "StringEscaperView",
            "StringLengthCounterView", "TextCounterView", "TextDeduplicatorView", "TextLineRemoverView", "LoremIpsumGeneratorView",
            "UUIDGeneratorView", "RandomStringGeneratorView", "BarcodeGeneratorDevToolView", "ASCIIArtGeneratorView", "HTMLEntityConverterView", "URLSlugGeneratorView"
        ]
        for t in textTools { tools.append(DevToolDefinition(name: t, category: "Text", description: "Text tool \(t)")) }

        // 5. Regex & Scheduling (4 Tools)
        let regexTools = ["RegexTesterView", "AdvancedRegexDebuggerDevToolView", "RegexSyntaxCheatsheetView", "CronParserView"]
        for r in regexTools { tools.append(DevToolDefinition(name: r, category: "Regex", description: "Regex/Cron tool \(r)")) }

        // 6. Web & Network Utilities (18 Tools)
        let webTools = [
            "APITesterView", "APIResponseViewerDevToolView", "CURLGeneratorDevToolView", "CURLConverterDevToolView", "DNSLookupView",
            "WhoisLookupView", "IPAddressInfoView", "PortScannerView", "PortLookupView", "SubnetCalculatorView",
            "NetworkReachabilityDevToolView", "WebhookTesterView", "HTTPStatusView", "HTTPHeaderParserView", "HTTPRequestHeaderBuilderView",
            "CookieParserView", "UserAgentParserView", "URLEncoderView"
        ]
        for w in webTools { tools.append(DevToolDefinition(name: w, category: "Network", description: "Web tool \(w)")) }

        // 7. CSS, Layout & Design (15 Tools)
        let designTools = [
            "CSSBorderRadiusGeneratorView", "CSSShadowGeneratorView", "CSSFlexboxPlaybookView", "CSSUnitConverterView", "BezierCurveVisualizerDevToolView",
            "BezierPathCodeDevToolView", "ColorConverterView", "HexToRGBAndHSLConverterView", "ColorContrastAnalyzerView", "AccessibilityContrastGridDevToolView",
            "ColorPaletteGeneratorDevToolView", "ColorGradientGeneratorView", "ColorBlendingDevToolView", "AspectRatioCalculatorView", "SFSymbolsReferenceView"
        ]
        for d in designTools { tools.append(DevToolDefinition(name: d, category: "Design", description: "Design tool \(d)")) }

        // 8. Minifiers & Optimizers (6 Tools)
        let minifiers = ["JSMinifierView", "CSSMinifierView", "HTMLMinifierView", "SVGMinifierView", "GzipCompressorView", "ImageBase64View"]
        for m in minifiers { tools.append(DevToolDefinition(name: m, category: "Minifiers", description: "Minifier tool \(m)")) }

        // 9. System & Hardware (14 Tools)
        let sysTools = [
            "CPUMonitorDevToolView", "FPSMonitorDevToolView", "EnergyImpactMonitorDevToolView", "BatteryStatusDevToolView", "DiskUsageAnalyzerDevToolView",
            "DeviceInfoView", "EnvVarInspectorDevToolView", "ClipboardInspectorDevToolView", "AppSandboxExplorerDevToolView", "AppStateInspectorDevToolView",
            "CacheViewerDevToolView", "BundleSizeAnalyzerDevToolView", "DeepLinkTesterDevToolView", "MACAddressGeneratorView"
        ]
        for s in sysTools { tools.append(DevToolDefinition(name: s, category: "System", description: "System tool \(s)")) }

        // 10. Cheatsheets & Guides (16 Tools)
        let cheatsheets = [
            "SwiftLanguageReferenceView", "SwiftConcurrencyCheatsheetView", "SwiftUIPerformanceCheatsheetView", "GitCheatsheetView", "GitBranchingStrategiesView",
            "LLDBDebuggerCheatsheetView", "SwiftLintConfigurationGuideView", "AppStoreGuidelinesCheatsheetView", "AppleSiliconOptimizationCheatsheetView", "iOSScreenResolutionsView",
            "XcodeShortcutsCheatsheetView", "MarkdownSyntaxCheatsheetView", "SemVerCheckerView", "TimestampConverterView", "TimezoneConverterView", "DateFormatterDevToolView"
        ]
        for cs in cheatsheets { tools.append(DevToolDefinition(name: cs, category: "Cheatsheets", description: "Cheatsheet tool \(cs)")) }

        // 11. Units & Misc (19 Tools)
        let misc = [
            "LengthConverterView", "WeightConverterView", "TemperatureConverterView", "PercentageCalculatorView", "MIMETypeLookupView",
            "DiffCheckerView", "MarkdownPreviewerView", "BreakpointManagerDevToolView", "DesignerDevToolView", "DevToolsMainView",
            "ExpandedDevTools", "AppIconSelectView", "AppIconManager", "AppIconPreviewGenerator", "CreditAndLicensesView",
            "ProjectInspectorView", "LocalizationManagerView", "TerminalView", "CodeDictionarySearchView"
        ]
        for mi in misc { tools.append(DevToolDefinition(name: mi, category: "Misc", description: "Misc tool \(mi)")) }
    }
}

public struct DevToolsDashboardView: View {
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"

    public init() {}

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Developer Utilities Suite (156 Tools)").font(.headline)
                Spacer()
                Text("Total Tools: \(DeveloperUtilitiesCatalog.shared.tools.count)")
            }
            .padding()

            List(DeveloperUtilitiesCatalog.shared.tools) { tool in
                HStack {
                    Text(tool.name).bold()
                    Spacer()
                    Text(tool.category).font(.caption).padding(4).background(Color.secondary.opacity(0.1)).cornerRadius(4)
                }
            }
        }
    }
}
