// swiftlint:disable file_length type_body_length line_length
import SwiftUI

struct FeedbackView: View {
    @ObservedObject
    private var feedbackModel: FeedbackModel = .shared

    @StateObject
    var prefs: AppPreferencesModel = .shared

    @State
    var showsAlert: Bool = false

    @State
    var isSubmitButtonPressed: Bool = false

    @Environment(\.openURL)
    private var openURL

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    basicInformationCard
                    descriptionCard
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
            }

            toolbarBottom
        }
        .frame(width: 980, height: 740)
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
            }
            .ignoresSafeArea()
        )
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)

                Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Feedback for CodeEdit")
                    .font(.system(size: 16, weight: .bold))
                Text("Help shape CodeEdit by reporting issues, bugs, and suggesting enhancements.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Link(destination: URL(string: "https://github.com/dylans2010/CodeEdit")!) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 11, weight: .medium))
                    Text("dylans2010/CodeEdit")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Basic Information Card
    private var basicInformationCard: some View {
        liquidGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 15))
                    Text("Basic Information")
                        .font(.system(size: 15, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        if isSubmitButtonPressed && feedbackModel.feedbackTitle.isEmpty {
                            Label("Please provide a descriptive title for your feedback:", systemImage: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12, weight: .medium))
                        } else {
                            Label("Title:", systemImage: "text.cursor")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }

                    TextField("Example: CodeEdit crashes when using autocomplete", text: $feedbackModel.feedbackTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if isSubmitButtonPressed && feedbackModel.issueAreaListSelection == "none" {
                                Label("Problem area:", systemImage: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12, weight: .medium))
                            } else {
                                Label("Problem Area:", systemImage: "square.grid.2x2")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }

                        Picker("", selection: $feedbackModel.issueAreaListSelection) {
                            ForEach(feedbackModel.issueAreaList) { area in
                                Text(area.name).tag(area.id)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if isSubmitButtonPressed && feedbackModel.feedbackTypeListSelection == "none" {
                                Label("Feedback type:", systemImage: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12, weight: .medium))
                            } else {
                                Label("Feedback Type:", systemImage: "tag")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }

                        Picker("", selection: $feedbackModel.feedbackTypeListSelection) {
                            ForEach(feedbackModel.feedbackTypeList) { type in
                                Text(type.name).tag(type.id)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: - Description Card
    private var descriptionCard: some View {
        liquidGlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 15))
                    Text("Details & Reproduction")
                        .font(.system(size: 15, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        if isSubmitButtonPressed && feedbackModel.issueDescription.isEmpty {
                            Label("Description (Required):", systemImage: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12, weight: .medium))
                        } else {
                            Label("Description:", systemImage: "text.alignleft")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }

                    TextEditor(text: $feedbackModel.issueDescription)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 90)
                        .padding(4)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("Steps to Reproduce:", systemImage: "list.number")
                        .font(.system(size: 12, weight: .medium))

                    TextEditor(text: $feedbackModel.stepsReproduceDescription)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(minHeight: 70)
                        .padding(4)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5)
                        )
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("What did you expect to happen?", systemImage: "checkmark.circle")
                            .font(.system(size: 12, weight: .medium))

                        TextEditor(text: $feedbackModel.expectationDescription)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(minHeight: 65)
                            .padding(4)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5)
                            )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label("What actually happened?", systemImage: "xmark.circle")
                            .font(.system(size: 12, weight: .medium))

                        TextEditor(text: $feedbackModel.whatHappenedDescription)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(minHeight: 65)
                            .padding(4)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Liquid Glass Container
    @ViewBuilder
    private func liquidGlassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.05),
                                        Color.accentColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
    }

    // MARK: - Bottom Toolbar
    private var toolbarBottom: some View {
        HStack(spacing: 12) {
            HelpButton(action: {
                if let url = URL(string: "https://github.com/dylans2010/CodeEdit/issues") {
                    openURL(url)
                }
            })

            Spacer()

            if feedbackModel.isSubmitted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Feedback submitted successfully!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            } else if feedbackModel.failedToSubmit {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Failed to submit feedback. Check GitHub account.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                }
                .transition(.opacity)
            }

            Button {
                feedbackModel.createIssue(
                    title: feedbackModel.feedbackTitle,
                    description: feedbackModel.issueDescription,
                    steps: feedbackModel.stepsReproduceDescription,
                    expectation: feedbackModel.expectationDescription,
                    actuallyHappened: feedbackModel.whatHappenedDescription
                )
                isSubmitButtonPressed = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 12))
                    Text("Submit Feedback")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .alert(isPresented: self.$showsAlert) {
                Alert(
                    title: Text("No GitHub Account"),
                    message: Text("A GitHub account is required to submit feedback to dylans2010/CodeEdit."),
                    primaryButton: .default(Text("Cancel")),
                    secondaryButton: .default(Text("Add Account"))
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    func showWindow() {
        FeedbackWindowController(view: self, size: NSSize(width: 980, height: 740)).showWindow(nil)
    }
}

// MARK: - VisualEffectView Helper
private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
