import Foundation

/// Reads brewing state from App Group UserDefaults, written by Flutter via the live_activities plugin.
struct BrewingData {
    let recipeName: String
    let stepDescription: String
    let currentStep: Int
    let totalSteps: Int
    let stepElapsedSeconds: Int
    let stepTotalSeconds: Int
    let isPaused: Bool
    let stepTimeRange: ClosedRange<Date>

    private static let defaults = UserDefaults(suiteName: "group.timer.coffee")

    init(activityId: String) {
        let d = BrewingData.defaults

        func key(_ k: String) -> String {
            return "\(activityId)_\(k)"
        }

        recipeName = d?.string(forKey: key("recipeName")) ?? "Brewing"
        stepDescription = d?.string(forKey: key("stepDescription")) ?? ""
        currentStep = d?.integer(forKey: key("currentStep")) ?? 1
        totalSteps = d?.integer(forKey: key("totalSteps")) ?? 1
        stepElapsedSeconds = d?.integer(forKey: key("stepElapsedSeconds")) ?? 0
        stepTotalSeconds = d?.integer(forKey: key("stepTotalSeconds")) ?? 0
        isPaused = (d?.integer(forKey: key("isPaused")) ?? 0) != 0

        let startMs = d?.double(forKey: key("stepStartDate")) ?? 0
        let endMs = d?.double(forKey: key("stepEndDate")) ?? 0
        let startDate = Date(timeIntervalSince1970: startMs / 1000.0)
        let endDate = Date(timeIntervalSince1970: endMs / 1000.0)

        // Ensure valid range (start <= end)
        if startDate <= endDate {
            stepTimeRange = startDate...endDate
        } else {
            let now = Date()
            stepTimeRange = now...now
        }
    }

    var progress: Double {
        guard stepTotalSeconds > 0 else { return 0 }
        return min(Double(stepElapsedSeconds) / Double(stepTotalSeconds), 1.0)
    }

    var stepLabel: String {
        return "\(currentStep)/\(totalSteps)"
    }
}
