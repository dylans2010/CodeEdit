import Cocoa

final class NSHapticFeedbackPerformerMock: NSObject, NSHapticFeedbackPerformer {

    var invokedPerform = false
    var invokedPerformCount = 0

    func perform(
        _ pattern: NSHapticFeedbackManager.FeedbackPattern,
        performanceTime: NSHapticFeedbackManager.PerformanceTime
    ) {
        invokedPerform = true
        invokedPerformCount += 1
    }
}
