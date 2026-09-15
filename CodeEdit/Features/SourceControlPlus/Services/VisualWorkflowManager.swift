//
//  VisualWorkflowManager.swift
//  CodeEdit
//
//

import Foundation

/// Manager creating and converting visual CI/CD pipelines into GitHub Actions YAML.
@MainActor
public final class VisualWorkflowManager: ObservableObject {
    public static let shared = VisualWorkflowManager()

    @Published public var workflowName: String = "CI Build & Test"
    @Published public var branchTrigger: String = "main"
    @Published public var steps: [WorkflowStep] = []

    public init() {
        self.steps = [
            WorkflowStep(name: "Checkout", stepType: .checkout),
            WorkflowStep(name: "Build", stepType: .buildScheme, command: "swift build"),
            WorkflowStep(name: "Test", stepType: .runTests, command: "swift test")
        ]
    }

    /// Adds a step to the active pipeline.
    public func addStep(name: String, stepType: WorkflowStepType, command: String = "") {
        steps.append(WorkflowStep(name: name, stepType: stepType, command: command))
    }

    /// Translates visual workflow steps into valid GitHub Actions .github/workflows/ci.yml content.
    public func exportToGitHubActionsYAML() -> String {
        var yaml = """
        name: \(workflowName)

        on:
          push:
            branches: [ "\(branchTrigger)" ]
          pull_request:
            branches: [ "\(branchTrigger)" ]

        jobs:
          build-and-test:
            runs-on: macos-latest

            steps:

        """

        for step in steps {
            switch step.stepType {
            case .checkout:
                yaml += """
                    - name: \(step.name)
                      uses: actions/checkout@v4


                """
            case .shellCommand, .runLinter, .buildScheme, .runTests, .deploy:
                let runCmd = step.command.isEmpty ? "echo '\(step.name)'" : step.command
                yaml += """
                    - name: \(step.name)
                      run: |
                        \(runCmd)


                """
            }
        }

        return yaml
    }

    /// Saves the workflow directly to .github/workflows/ci.yml in the target project.
    public func saveToProject(projectURL: URL) throws {
        let workflowsDir = projectURL.appendingPathComponent(".github/workflows")
        try FileManager.default.createDirectory(at: workflowsDir, withIntermediateDirectories: true)
        let fileURL = workflowsDir.appendingPathComponent("ci.yml")
        let yaml = exportToGitHubActionsYAML()
        try yaml.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
