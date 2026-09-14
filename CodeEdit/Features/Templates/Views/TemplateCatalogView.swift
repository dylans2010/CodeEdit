import SwiftUI
import AppKit

struct TemplateCatalogView: View {
    @Binding var isPresented: Bool
    let openDocument: (URL?, @escaping () -> Void) -> Void
    let dismissWindow: () -> Void

    @StateObject private var templateManager = TemplateManager.shared
    @State private var selectedCategory: TemplateCategory = .all
    @State private var searchText = ""
    @State private var selectedTemplate: ProjectTemplate?
    @State private var projectName = ""
    @State private var showingAppleSetup = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 380), spacing: 14)
    ]

    var body: some View {
        Group {
            if showingAppleSetup, let template = selectedTemplate {
                AppleProjectSetupView(
                    template: template,
                    isPresented: $isPresented,
                    onBack: { showingAppleSetup = false },
                    openDocument: openDocument,
                    dismissWindow: dismissWindow
                )
            } else {
                mainCatalogLayout
            }
        }
        .onAppear {
            if selectedTemplate == nil {
                selectedTemplate = templateManager.templates.first
                projectName = selectedTemplate?.defaultProjectName ?? "MyProject"
            }
        }
    }

    private var mainCatalogLayout: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            HStack(spacing: 0) {
                categorySidebar
                    .frame(width: 220)
                Divider()
                templateGridArea
                if let template = selectedTemplate {
                    Divider()
                    TemplateDetailView(template: template, projectName: $projectName)
                        .frame(width: 280)
                }
            }
            Divider()
            footerBar
        }
        .frame(width: 960, height: 640)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Template Error"),
                message: Text(errorMessage ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Choose a Template")
                    .font(.system(size: 18, weight: .bold))
                Text("Select from \(templateManager.templates.count) preset templates to start a new project")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
            searchBar
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            TextField("Search templates...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .frame(width: 260)
    }

    // MARK: - Category Sidebar

    private var categorySidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CATEGORIES")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            List(TemplateCategory.allCases, id: \.self, selection: $selectedCategory) { category in
                categoryRow(for: category)
            }
            .listStyle(.sidebar)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
    }

    private func categoryRow(for category: TemplateCategory) -> some View {
        HStack(spacing: 10) {
            Image(systemName: category.iconName)
                .font(.system(size: 13))
                .foregroundColor(selectedCategory == category ? .accentColor : .secondary)
                .frame(width: 18)

            Text(category.rawValue)
                .font(.system(size: 12, weight: selectedCategory == category ? .medium : .regular))

            Spacer()

            Text("\(countForCategory(category))")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.secondary.opacity(0.12)))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedCategory = category
        }
    }

    private func countForCategory(_ category: TemplateCategory) -> Int {
        if category == .all {
            return templateManager.templates.count
        }
        return templateManager.templates.filter { $0.category == category }.count
    }

    // MARK: - Template Grid

    private var filteredList: [ProjectTemplate] {
        templateManager.filteredTemplates(category: selectedCategory, searchQuery: searchText)
    }

    private var templateGridArea: some View {
        ScrollView {
            if filteredList.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(filteredList) { template in
                        TemplateCardView(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id,
                            onSelect: {
                                selectedTemplate = template
                                projectName = template.defaultProjectName
                            },
                            onChoose: {
                                handleSelect(template: template)
                            }
                        )
                    }
                }
                .padding(18)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No templates found")
                .font(.headline)
            Text("Try adjusting your search query or select another category.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack {
            Text("\(filteredList.count) templates available")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Spacer()

            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)

            Button(selectedTemplate?.category == .apple ? "Configure Apple Project..." : "Create Project...") {
                if let template = selectedTemplate {
                    handleSelect(template: template)
                }
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(selectedTemplate == nil || projectName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Selection & Creation Handling

    private func handleSelect(template: ProjectTemplate) {
        selectedTemplate = template
        projectName = template.defaultProjectName
        if template.category == .apple {
            showingAppleSetup = true
        } else {
            startCreationFlow(template: template)
        }
    }

    private func startCreationFlow(template: ProjectTemplate) {
        let name = projectName.trimmingCharacters(in: .whitespaces).isEmpty ? template.defaultProjectName : projectName

        let panel = NSSavePanel()
        panel.title = "Create New Project"
        panel.prompt = "Create"
        panel.nameFieldStringValue = name
        panel.canCreateDirectories = true
        panel.showsTagField = false

        guard panel.runModal() == .OK, let targetURL = panel.url else {
            return
        }

        do {
            try templateManager.instantiate(
                template: template,
                at: targetURL,
                projectName: name
            )
            isPresented = false
            openDocument(targetURL, dismissWindow)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
