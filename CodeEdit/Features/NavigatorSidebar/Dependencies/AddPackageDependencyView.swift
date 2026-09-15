//
//  AddPackageDependencyView.swift
//  CodeEdit
//
//

// swiftlint:disable line_length

import SwiftUI

struct AddPackageDependencyView: View {
    let workspaceURL: URL
    @Binding var isPresented: Bool
    let onAdded: () -> Void

    @State private var packageURL: String = ""
    @State private var requirementType: String = "Up to Next Major"
    @State private var requirementValue: String = "1.0.0"
    @State private var isAdding: Bool = false
    @State private var errorMessage: String?

    let requirementTypes = ["Up to Next Major", "Exact Version", "Branch"]

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Package Repository URL")
                        .font(.system(size: 12, weight: .semibold))
                    TextField("https://github.com/owner/repo.git", text: $packageURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Dependency Rule")
                        .font(.system(size: 12, weight: .semibold))

                    Picker("", selection: $requirementType) {
                        ForEach(requirementTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(requirementType == "Branch" ? "Branch Name:" : "Version:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        TextField(requirementType == "Branch" ? "main" : "1.0.0", text: $requirementValue)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                    }
                    .padding(.top, 4)
                }

                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }

                Spacer()
            }
            .padding(20)

            Divider()
            footerBar
        }
        .frame(width: 440, height: 280)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var headerBar: some View {
        HStack {
            Image(systemName: "shippingbox.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 18))
            Text("Add Swift Package Dependency")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var footerBar: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            if isAdding {
                ProgressView()
                    .scaleEffect(0.7)
            }

            Button("Add Package") {
                addDependency()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(packageURL.trimmingCharacters(in: .whitespaces).isEmpty || isAdding)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func addDependency() {
        isAdding = true
        errorMessage = nil

        Task {
            do {
                try await WorkspaceDependencyService.shared.addPackageDependency(
                    workspaceURL: workspaceURL,
                    packageURL: packageURL,
                    requirementType: requirementType,
                    requirementValue: requirementValue
                )
                await MainActor.run {
                    self.isAdding = false
                    self.isPresented = false
                    self.onAdded()
                }
            } catch {
                await MainActor.run {
                    self.isAdding = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
