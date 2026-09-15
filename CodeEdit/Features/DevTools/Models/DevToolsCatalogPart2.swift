//
//  DevToolsCatalogPart2.swift
//  CodeEdit
//
//

import Foundation

/// Catalog partition 2: Tools for Categories 5 through 8 (43 Tools).
public struct DevToolsCatalogPart2: Sendable {
    public static let tools: [DevToolItem] = [
        // Category 5: Regex & Scheduling (4 Tools)
        DevToolItem(id: "regex_tester", title: "Regex Match Tester", category: .regexScheduling,
                    summary: "Real-time regular expressions.", iconName: "magnifyingglass"),
        DevToolItem(id: "advanced_regex_debugger", title: "Regex Backtrack Debugger", category: .regexScheduling,
                    summary: "Step-by-step regex visualizer.", iconName: "arrow.triangle.branch"),
        DevToolItem(id: "regex_syntax_cheatsheet", title: "Regex Syntax Cheatsheet", category: .regexScheduling,
                    summary: "Character classes and assertions.", iconName: "book.pages"),
        DevToolItem(id: "cron_parser", title: "Crontab Expression Parser", category: .regexScheduling,
                    summary: "Human-readable cron schedule.", iconName: "calendar"),

        // Category 6: Web & Network Utilities (18 Tools)
        DevToolItem(id: "api_tester", title: "Lightweight API Client", category: .webNetwork,
                    summary: "HTTP requests with headers/body.", iconName: "paperplane"),
        DevToolItem(id: "api_response_viewer", title: "API Response Formatter", category: .webNetwork,
                    summary: "Formatted JSON/XML response tree.", iconName: "doc.plaintext"),
        DevToolItem(id: "curl_generator", title: "Visual cURL Generator", category: .webNetwork,
                    summary: "Generates ready-to-run curl.", iconName: "terminal"),
        DevToolItem(id: "curl_converter", title: "cURL to Code Converter", category: .webNetwork,
                    summary: "cURL to Swift, JS, Python.", iconName: "arrow.triangle.2.circlepath"),
        DevToolItem(id: "dns_lookup", title: "DNS Record Resolver", category: .webNetwork,
                    summary: "Resolves A, AAAA, CNAME, MX.", iconName: "globe"),
        DevToolItem(id: "whois_lookup", title: "WHOIS Domain Lookup", category: .webNetwork,
                    summary: "Domain registration databases.", iconName: "person.text.rectangle"),
        DevToolItem(id: "ip_address_info", title: "IP Geolocation Inspector", category: .webNetwork,
                    summary: "ISP, ASN, and reverse DNS.", iconName: "location.magnifyingglass"),
        DevToolItem(id: "port_scanner", title: "TCP Port Scanner", category: .webNetwork,
                    summary: "Scans open listening sockets.", iconName: "antenna.radiowaves.left.and.right"),
        DevToolItem(id: "port_lookup", title: "Service Port Reference", category: .webNetwork,
                    summary: "Searches standard service ports.", iconName: "list.bullet.rectangle"),
        DevToolItem(id: "subnet_calculator", title: "IPv4/IPv6 CIDR Calculator", category: .webNetwork,
                    summary: "Mask and usable host ranges.", iconName: "network"),
        DevToolItem(id: "network_reachability", title: "Network Reachability & Ping", category: .webNetwork,
                    summary: "Measures ping and jitter.", iconName: "waveform.path.ecg"),
        DevToolItem(id: "webhook_tester", title: "Webhook Payload Inspector", category: .webNetwork,
                    summary: "Inspects incoming payloads.", iconName: "arrow.down.message"),
        DevToolItem(id: "http_status_lookup", title: "HTTP Status Code Guide", category: .webNetwork,
                    summary: "Reference guide for codes 100-599.", iconName: "info.circle"),
        DevToolItem(id: "http_header_parser", title: "HTTP Header Inspector", category: .webNetwork,
                    summary: "CORS, CSP, and Cache-Control.", iconName: "doc.badge.gearshape"),
        DevToolItem(id: "request_header_builder", title: "Request Header Builder", category: .webNetwork,
                    summary: "Visual header configuration.", iconName: "slider.horizontal.3"),
        DevToolItem(id: "cookie_parser", title: "Cookie Attribute Inspector", category: .webNetwork,
                    summary: "Validates Set-Cookie attributes.", iconName: "circle.grid.2x2"),
        DevToolItem(id: "user_agent_parser", title: "User Agent String Parser", category: .webNetwork,
                    summary: "Extracts OS and browser engine.", iconName: "desktopcomputer"),
        DevToolItem(id: "url_encoder_decomposer", title: "URL Encoder & Decomposer", category: .webNetwork,
                    summary: "URL query items and path.", iconName: "link.badge.plus"),

        // Category 7: CSS, Layout & Design Utilities (15 Tools)
        DevToolItem(id: "css_border_radius", title: "CSS Border Radius Playground", category: .cssDesign,
                    summary: "8-point curve generator.", iconName: "square.dashed"),
        DevToolItem(id: "css_shadow_generator", title: "CSS Box Shadow Generator", category: .cssDesign,
                    summary: "Multi-layer CSS box shadows.", iconName: "shadow"),
        DevToolItem(id: "css_flexbox_playbook", title: "Flexbox Layout Sandbox", category: .cssDesign,
                    summary: "Interactive flex behaviors.", iconName: "rectangle.split.3x1"),
        DevToolItem(id: "css_unit_converter", title: "CSS Unit Converter", category: .cssDesign,
                    summary: "Converts px, rem, em, pt, %.", iconName: "ruler"),
        DevToolItem(id: "bezier_curve_visualizer", title: "Bezier Curve Editor", category: .cssDesign,
                    summary: "Cubic bezier timing curve.", iconName: "waveform"),
        DevToolItem(id: "bezier_path_code", title: "Swift UIBezierPath Code", category: .cssDesign,
                    summary: "Generates SwiftUI Path code.", iconName: "pencil.and.outline"),
        DevToolItem(id: "color_converter", title: "Color Space Converter", category: .cssDesign,
                    summary: "HEX, RGB, HSL, Swift Color.", iconName: "paintpalette"),
        DevToolItem(id: "hex_rgb_hsl_converter", title: "Hex to RGB & HSL", category: .cssDesign,
                    summary: "Fast color conversion.", iconName: "eyedropper"),
        DevToolItem(id: "color_contrast_analyzer", title: "WCAG 2.1 Contrast Checker", category: .cssDesign,
                    summary: "Tests foreground/background.", iconName: "circle.righthalf.filled"),
        DevToolItem(id: "contrast_matrix_grid", title: "Contrast Matrix Grid", category: .cssDesign,
                    summary: "Tests multiple color combos.", iconName: "grid"),
        DevToolItem(id: "color_palette_generator", title: "Harmonious Color Palettes", category: .cssDesign,
                    summary: "Analogous and triadic palettes.", iconName: "swatchpalette"),
        DevToolItem(id: "color_gradient_generator", title: "CSS & SwiftUI Gradients", category: .cssDesign,
                    summary: "Linear and radial gradients.", iconName: "circle.circle"),
        DevToolItem(id: "color_mixer_blender", title: "Color Channel Blender", category: .cssDesign,
                    summary: "Multiply, screen, overlay.", iconName: "drop"),
        DevToolItem(id: "aspect_ratio_calculator", title: "Aspect Ratio Calculator", category: .cssDesign,
                    summary: "16:9, 4:3, 21:9 dimension ratios.", iconName: "aspectratio"),
        DevToolItem(id: "sf_symbols_reference", title: "SF Symbols Catalog", category: .cssDesign,
                    summary: "Searchable Apple SF Symbols.", iconName: "star.circle"),

        // Category 8: Minifiers & Asset Optimizers (6 Tools)
        DevToolItem(id: "js_minifier", title: "JavaScript Minifier", category: .minifiersOptimizers,
                    summary: "Strips whitespace and comments.", iconName: "arrow.down.right.and.arrow.up.left"),
        DevToolItem(id: "css_minifier", title: "CSS Minifier", category: .minifiersOptimizers,
                    summary: "Compresses CSS stylesheets.", iconName: "arrow.down.right.and.arrow.up.left"),
        DevToolItem(id: "html_minifier", title: "HTML Document Minifier", category: .minifiersOptimizers,
                    summary: "Strips comments and whitespace.", iconName: "arrow.down.right.and.arrow.up.left"),
        DevToolItem(id: "svg_minifier", title: "SVG Vector Optimizer", category: .minifiersOptimizers,
                    summary: "Cleans vector metadata.", iconName: "diamond"),
        DevToolItem(id: "gzip_compressor", title: "Gzip Compression Estimator", category: .minifiersOptimizers,
                    summary: "Calculates compression ratios.", iconName: "archivebox"),
        DevToolItem(id: "image_base64_converter", title: "Image to Base64 URI", category: .minifiersOptimizers,
                    summary: "PNG/JPEG to data URI string.", iconName: "photo.stack")
    ]
}
