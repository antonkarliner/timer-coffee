import ActivityKit
import Foundation

/// Required by the live_activities Flutter plugin.
/// The plugin writes data to App Group UserDefaults with keys prefixed by the activity UUID.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {
        var appGroupId: String?
        var updateTimestamp: Double?
        var recipeName: String?
        var stepDescription: String?
        var currentStep: Int?
        var totalSteps: Int?
        var stepElapsedSeconds: Int?
        var stepTotalSeconds: Int?
        var stepStartDateMs: Int?
        var stepEndDateMs: Int?
        var effectiveAtMs: Int?
        var isPaused: Bool?
        var brewStartDateMs: Int?
        var stepDurationsSeconds: [Int]?
        var stepDescriptions: [String]?
    }

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}
