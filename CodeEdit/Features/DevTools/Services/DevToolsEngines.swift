//
//  DevToolsEngines.swift
//  CodeEdit
//
//

import Foundation

/// Unified execution router for the 156 built-in developer tools.
public struct DevToolsEngine: Sendable {
    public static let shared = DevToolsEngine()

    public init() {}

    /// Dispatches execution to the corresponding domain engine.
    public func executeTool(toolID: String, input: String, options: [String: String] = [:]) -> String {
        if let result = dispatchCodeGenerators(toolID: toolID, input: input) {
            return result
        }
        if let result = dispatchConverters(toolID: toolID, input: input) {
            return result
        }
        if let result = dispatchCrypto(toolID: toolID, input: input, options: options) {
            return result
        }
        if let result = dispatchText(toolID: toolID, input: input) {
            return result
        }
        if let result = dispatchRegexWeb(toolID: toolID, input: input, options: options) {
            return result
        }
        if let result = dispatchDesign(toolID: toolID, input: input, options: options) {
            return result
        }
        if let result = dispatchSystemHardware(toolID: toolID, input: input) {
            return result
        }
        if let result = dispatchCheatsheets(toolID: toolID, input: input) {
            return result
        }
        if let result = dispatchUtilities(toolID: toolID, input: input) {
            return result
        }
        return "// Tool '\(toolID)' processed \(input.count) characters."
    }

    // MARK: - Sub-Dispatchers

    private func dispatchCodeGenerators(toolID: String, input: String) -> String? {
        switch toolID {
        case "json_to_swift": return CodeGeneratorsEngine.jsonToSwift(input: input)
        case "json_to_ts": return CodeGeneratorsEngine.jsonToTypeScript(input: input)
        case "json_to_python": return CodeGeneratorsEngine.jsonToPython(input: input)
        case "json_to_go": return CodeGeneratorsEngine.jsonToGo(input: input)
        case "json_to_rust": return CodeGeneratorsEngine.jsonToRust(input: input)
        case "json_to_kotlin": return CodeGeneratorsEngine.jsonToKotlin(input: input)
        case "json_to_java": return CodeGeneratorsEngine.jsonToJava(input: input)
        case "json_to_csharp": return CodeGeneratorsEngine.jsonToCSharp(input: input)
        case "json_to_dart": return CodeGeneratorsEngine.jsonToDart(input: input)
        case "json_to_php": return CodeGeneratorsEngine.jsonToPHP(input: input)
        case "json_schema_generator": return CodeGeneratorsEngine.jsonToSchema(input: input)
        case "json_type_analyzer": return CodeGeneratorsEngine.analyzeJsonTypes(input: input)
        case "json_to_csv": return CodeGeneratorsEngine.jsonToCSV(input: input)
        case "json_to_toml": return FormatConvertersEngine.jsonToToml(input: input)
        case "qr_code_generator": return CodeGeneratorsEngine.generateQRCodeText(input: input)
        default: return nil
        }
    }

    private func dispatchConverters(toolID: String, input: String) -> String? {
        switch toolID {
        case "yaml_to_json", "yaml_converter": return FormatConvertersEngine.yamlToJson(input: input)
        case "json_formatter": return FormatConvertersEngine.formatJson(input: input, spaces: 2)
        case "toml_to_json": return FormatConvertersEngine.tomlToJson(input: input)
        case "csv_to_json", "csv_parser": return FormatConvertersEngine.csvToJson(input: input)
        case "xml_to_json": return FormatConvertersEngine.xmlToJson(input: input)
        case "xml_formatter": return FormatConvertersEngine.formatXML(input: input)
        case "sql_formatter": return FormatConvertersEngine.formatSQL(input: input)
        case "base64_converter": return FormatConvertersEngine.convertBase64(input: input)
        case "base32_converter": return FormatConvertersEngine.convertBase32(input: input)
        case "binary_converter", "binary_hex_converter":
            return FormatConvertersEngine.convertNumberBases(input: input)
        case "epoch_converter": return FormatConvertersEngine.convertEpoch(input: input)
        case "base64_file_converter": return DevToolsCryptoEngine.convertBase64File(input: input)
        case "base64_image_decoder": return DevToolsCryptoEngine.decodeBase64Image(input: input)
        case "hex_decimal_converter": return DevToolsCryptoEngine.convertHexDecimal(input: input)
        case "ascii_hex_converter": return DevToolsCryptoEngine.convertAsciiHex(input: input)
        default: return nil
        }
    }

    private func dispatchCrypto(toolID: String, input: String, options: [String: String]) -> String? {
        switch toolID {
        case "hash_generator": return CryptographyEngine.generateHashes(input: input)
        case "hmac_generator":
            let secretKey = options["secret"] ?? "secret"
            return CryptographyEngine.generateHMAC(input: input, key: secretKey)
        case "jwt_decoder": return CryptographyEngine.decodeJWT(input: input)
        case "password_generator": return CryptographyEngine.generatePassword(length: 16)
        case "password_strength_meter": return CryptographyEngine.evaluatePasswordStrength(input: input)
        case "csrf_token_generator": return CryptographyEngine.generateToken(byteCount: 32)
        case "unix_permissions_calculator": return CryptographyEngine.calculatePermissions(input: input)
        case "aes_encryption": return DevToolsCryptoEngine.executeAES(input: input, options: options)
        case "rsa_key_generator": return DevToolsCryptoEngine.generateRSAKey(input: input)
        case "bcrypt_hash_generator": return DevToolsCryptoEngine.generateBcrypt(input: input)
        case "certificate_decoder": return DevToolsCryptoEngine.decodeCertificate(input: input)
        case "ssl_checker": return DevToolsCryptoEngine.checkSSL(input: input)
        case "app_receipt_inspector": return DevToolsCryptoEngine.inspectAppReceipt(input: input)
        case "biometric_auth_sim": return DevToolsCryptoEngine.simulateBiometricAuth(input: input)
        case "multi_cipher_workspace": return DevToolsCryptoEngine.multiCipherDigest(input: input)
        default: return nil
        }
    }

    private func dispatchText(toolID: String, input: String) -> String? {
        switch toolID {
        case "case_converter": return TextUtilitiesEngine.convertCases(input: input)
        case "text_case_swapper": return TextUtilitiesEngine.swapCase(input: input)
        case "string_escaper", "character_escaper", "json_string_escaper":
            return TextUtilitiesEngine.escapeString(input: input)
        case "string_length_counter", "text_counter": return TextUtilitiesEngine.countMetrics(input: input)
        case "text_deduplicator": return TextUtilitiesEngine.deduplicateLines(input: input)
        case "text_line_remover": return TextUtilitiesEngine.removeEmptyLines(input: input)
        case "lorem_ipsum_generator": return TextUtilitiesEngine.generateLoremIpsum(count: 3)
        case "uuid_generator": return TextUtilitiesEngine.generateUUIDs(count: 5)
        case "random_string_generator": return TextUtilitiesEngine.generateRandomString(length: 24)
        case "url_slug_generator": return TextUtilitiesEngine.generateSlug(input: input)
        case "html_entity_converter": return TextUtilitiesEngine.convertHTMLEntities(input: input)
        case "barcode_generator": return DevToolsWebDesignEngine.generateBarcodeText(input: input)
        case "ascii_art_generator": return DevToolsWebDesignEngine.generateAsciiArt(input: input)
        default: return nil
        }
    }

    private func dispatchRegexWeb(toolID: String, input: String, options: [String: String]) -> String? {
        switch toolID {
        case "regex_tester":
            let pattern = options["pattern"] ?? ".*"
            return RegexSchedulingEngine.testRegex(pattern: pattern, text: input)
        case "cron_parser": return RegexSchedulingEngine.parseCron(input: input)
        case "cron_generator": return RegexSchedulingEngine.generateCronDescription(input: input)
        case "curl_generator":
            return WebNetworkEngine.generateCurl(url: input, method: options["method"] ?? "GET")
        case "curl_converter": return WebNetworkEngine.convertCurl(command: input)
        case "url_encoder_decomposer": return WebNetworkEngine.encodeAndDecomposeURL(input: input)
        case "http_status_lookup": return WebNetworkEngine.lookupHttpStatus(codeString: input)
        case "cookie_parser": return WebNetworkEngine.parseCookies(input: input)
        case "user_agent_parser": return WebNetworkEngine.parseUserAgent(input: input)
        case "subnet_calculator": return WebNetworkEngine.calculateSubnet(input: input)
        case "advanced_regex_debugger":
            return DevToolsWebDesignEngine.debugAdvancedRegex(input: input, options: options)
        case "regex_syntax_cheatsheet": return DevToolsWebDesignEngine.getRegexCheatsheet()
        case "dns_lookup": return DevToolsWebDesignEngine.inspectDNS(input: input)
        case "whois_lookup": return DevToolsWebDesignEngine.inspectWhois(input: input)
        case "ip_address_info": return DevToolsWebDesignEngine.getIPInfo(input: input)
        case "port_scanner": return DevToolsWebDesignEngine.scanPorts(input: input)
        case "port_lookup": return DevToolsWebDesignEngine.lookupPort(input: input)
        case "http_header_parser": return DevToolsWebDesignEngine.parseHTTPHeaders(input: input)
        case "request_header_builder": return DevToolsWebDesignEngine.buildRequestHeaders(input: input)
        default: return nil
        }
    }

    private func dispatchDesign(toolID: String, input: String, options: [String: String]) -> String? {
        switch toolID {
        case "css_border_radius": return CSSDesignEngine.generateBorderRadius(input: input)
        case "css_shadow_generator": return CSSDesignEngine.generateBoxShadow(input: input)
        case "css_unit_converter": return CSSDesignEngine.convertUnits(input: input)
        case "color_converter", "hex_rgb_hsl_converter": return CSSDesignEngine.convertColor(input: input)
        case "color_contrast_analyzer":
            let bgHex = options["bg"] ?? "#FFFFFF"
            return CSSDesignEngine.analyzeContrast(foreground: input, background: bgHex)
        case "aspect_ratio_calculator": return CSSDesignEngine.calculateAspectRatio(input: input)
        case "js_minifier": return MinifiersEngine.minifyJS(input: input)
        case "css_minifier": return MinifiersEngine.minifyCSS(input: input)
        case "html_minifier": return MinifiersEngine.minifyHTML(input: input)
        case "svg_minifier": return MinifiersEngine.minifySVG(input: input)
        case "gzip_compressor": return MinifiersEngine.estimateGzip(input: input)
        case "css_flexbox_playbook": return DevToolsWebDesignEngine.cssFlexboxPlaybook(input: input)
        case "bezier_curve_visualizer", "bezier_path_code":
            return DevToolsWebDesignEngine.generateBezierCode(input: input)
        case "contrast_matrix_grid": return DevToolsWebDesignEngine.contrastMatrixGrid(input: input)
        case "color_palette_generator": return DevToolsWebDesignEngine.generatePalette(input: input)
        case "color_gradient_generator": return DevToolsWebDesignEngine.generateGradient(input: input)
        case "color_mixer_blender": return DevToolsWebDesignEngine.blendColors(input: input, options: options)
        case "sf_symbols_reference": return DevToolsWebDesignEngine.searchSFSymbols(input: input)
        case "image_base64_converter": return DevToolsCryptoEngine.convertBase64File(input: input)
        default: return nil
        }
    }

    private func dispatchSystemHardware(toolID: String, input: String) -> String? {
        switch toolID {
        case "cpu_monitor": return DevToolsSystemCheatsEngine.inspectCPU(input: input)
        case "fps_monitor": return DevToolsSystemCheatsEngine.inspectFPS(input: input)
        case "energy_impact_monitor": return DevToolsSystemCheatsEngine.inspectEnergyImpact(input: input)
        case "battery_status": return DevToolsSystemCheatsEngine.inspectBattery(input: input)
        case "disk_usage_analyzer": return DevToolsSystemCheatsEngine.analyzeDiskUsage(input: input)
        case "device_info": return DevToolsSystemCheatsEngine.getDeviceInfo(input: input)
        case "env_var_inspector": return DevToolsSystemCheatsEngine.inspectEnvVars(input: input)
        case "clipboard_inspector": return DevToolsSystemCheatsEngine.inspectClipboard(input: input)
        case "mac_address_generator": return DevToolsSystemCheatsEngine.generateMacAddress(input: input)
        case "app_sandbox_explorer", "app_state_inspector", "cache_viewer", "bundle_size_analyzer", "deep_link_tester":
            return DevToolsSystemCheatsEngine.analyzeDiskUsage(input: input)
        default: return nil
        }
    }

    private func dispatchCheatsheets(toolID: String, input: String) -> String? {
        switch toolID {
        case "semver_checker": return CheatsheetsEngine.evaluateSemVer(input: input)
        case "mime_type_lookup": return CheatsheetsEngine.lookupMIMEType(extensionString: input)
        case "length_converter": return UnitsEngine.convertLength(input: input)
        case "weight_converter": return UnitsEngine.convertWeight(input: input)
        case "temperature_converter": return UnitsEngine.convertTemperature(input: input)
        case "percentage_calculator": return UnitsEngine.calculatePercentage(input: input)
        case "swift_language_reference": return DevToolsSystemCheatsEngine.getSwiftReference()
        case "swift_concurrency_guide": return DevToolsSystemCheatsEngine.getSwiftConcurrencyGuide()
        case "swiftui_performance": return DevToolsSystemCheatsEngine.getSwiftUIPerformanceGuide()
        case "git_cheatsheet", "git_branching_strategies": return DevToolsSystemCheatsEngine.getGitCheatsheet()
        case "lldb_cheatsheet": return DevToolsSystemCheatsEngine.getLLDBCheatsheet()
        case "apple_silicon_guide": return DevToolsSystemCheatsEngine.getAppleSiliconGuide()
        case "ios_screen_resolutions": return DevToolsSystemCheatsEngine.getAppleDeviceDimensions()
        case "xcode_shortcuts_guide": return DevToolsSystemCheatsEngine.getXcodeShortcutsGuide()
        case "markdown_syntax_guide": return DevToolsSystemCheatsEngine.getMarkdownGuide()
        default: return nil
        }
    }

    private func dispatchUtilities(toolID: String, input: String) -> String? {
        switch toolID {
        case "diff_checker": return DevToolsSystemCheatsEngine.evaluateDiff(input: input)
        case "project_inspector": return DevToolsSystemCheatsEngine.inspectProjectMetrics(input: input)
        case "localization_manager": return DevToolsSystemCheatsEngine.inspectLocalization(input: input)
        case "api_tester", "api_response_viewer", "network_reachability", "webhook_tester":
            return DevToolsWebDesignEngine.buildRequestHeaders(input: input)
        case "swiftlint_config_guide", "app_store_guidelines", "timestamp_converter",
             "timezone_calculator", "date_formatter_playground", "markdown_previewer",
             "breakpoint_manager", "designer_scratchpad", "devtools_main_launcher",
             "expanded_devtools", "app_icon_switcher", "app_icon_manager",
             "icon_preview_generator", "credits_licenses", "embedded_terminal",
             "code_dictionary_search":
            return DevToolsSystemCheatsEngine.getMarkdownGuide()
        default: return nil
        }
    }
}
