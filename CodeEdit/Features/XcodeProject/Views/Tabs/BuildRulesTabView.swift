//
//  BuildRulesTabView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 14/09/26.
//

import SwiftUI

struct BuildRulesTabView: View {
    @ObservedObject var manager: XcodeProjectManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                systemRulesSection
                customRulesSection
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Build Rules")
                    .font(.headline)
                Text("Specify how Xcode processes files of particular types during build.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var systemRulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "gearshape.2")
                    .foregroundColor(.accentColor)
                Text("System Build Rules")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                ruleRow(name: "C, C++, Objective-C, and Objective-C++ source files", compiler: "Default Compiler (Apple Clang)")
                Divider()
                ruleRow(name: "Swift source files", compiler: "Swift Compiler")
                Divider()
                ruleRow(name: "Asset Catalogs", compiler: "Asset Catalog Compiler (actool)")
                Divider()
                ruleRow(name: "Interface Builder XIBs and Storyboards", compiler: "Interface Builder Compiler (ibtool)")
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private var customRulesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundColor(.accentColor)
                Text("Custom Build Rules")
                    .font(.headline)
            }

            let rules = manager.selectedTarget?.buildRules ?? []

            if rules.isEmpty {
                Text("No custom build rules configured for this target.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 0) {
                    ForEach(rules) { rule in
                        ruleRow(name: rule.name, compiler: rule.compilerSpec)
                        Divider()
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
        }
    }

    private func ruleRow(name: String, compiler: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                Text(compiler)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
