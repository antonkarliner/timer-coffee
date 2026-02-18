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

    private enum CandidateSource {
        case push
        case schedule
        case explicit
    }

    private struct Candidate {
        let recipeName: String
        let stepDescription: String
        let currentStep: Int
        let totalSteps: Int
        let stepElapsedSeconds: Int
        let stepTotalSeconds: Int
        let isPaused: Bool
        let stepTimeRange: ClosedRange<Date>
        let effectiveAtMs: Int?
        let source: CandidateSource
    }

    private static let defaults = UserDefaults(suiteName: "group.timer.coffee")
    private static let boundaryAcceptanceToleranceMs = 1500

    init(activityId: String, state: LiveActivitiesAppAttributes.ContentState? = nil) {
        let d = BrewingData.defaults

        func key(_ k: String) -> String {
            return "\(activityId)_\(k)"
        }

        let storedRecipeName = d?.string(forKey: key("recipeName")) ?? "Brewing"
        let storedDescription = d?.string(forKey: key("stepDescription")) ?? ""
        let storedCurrentStep = d?.integer(forKey: key("currentStep")) ?? 1
        let storedTotalSteps = d?.integer(forKey: key("totalSteps")) ?? 1
        let storedElapsed = d?.integer(forKey: key("stepElapsedSeconds")) ?? 0
        let storedStepTotal = d?.integer(forKey: key("stepTotalSeconds")) ?? 0
        let storedIsPaused = (d?.integer(forKey: key("isPaused")) ?? 0) != 0

        let rawDurations = d?.array(forKey: key("stepDurationsSeconds")) ?? []
        let scheduleDurations: [Int] = rawDurations.compactMap { value in
            if let intValue = value as? Int {
                return intValue
            }
            if let number = value as? NSNumber {
                return number.intValue
            }
            if let stringValue = value as? String, let intValue = Int(stringValue) {
                return intValue
            }
            return nil
        }.filter { $0 > 0 }

        let scheduleDescriptions = d?.stringArray(forKey: key("stepDescriptions")) ?? []
        let brewStartMs = d?.double(forKey: key("brewStartDate")) ?? 0

        let startMs = d?.double(forKey: key("stepStartDate")) ?? 0
        let endMs = d?.double(forKey: key("stepEndDate")) ?? 0
        let storedStartDate = Date(timeIntervalSince1970: startMs / 1000.0)
        let storedEndDate = Date(timeIntervalSince1970: endMs / 1000.0)

        let pushCandidate = BrewingData.makePushCandidate(state: state)
        let scheduleCandidate = BrewingData.makeScheduleCandidate(
            recipeName: storedRecipeName,
            fallbackDescription: storedDescription,
            isPaused: storedIsPaused,
            stepDurations: scheduleDurations,
            stepDescriptions: scheduleDescriptions,
            brewStartMs: brewStartMs
        )
        let explicitCandidate = BrewingData.makeExplicitCandidate(
            recipeName: storedRecipeName,
            stepDescription: storedDescription,
            currentStep: storedCurrentStep,
            totalSteps: storedTotalSteps,
            elapsedSeconds: storedElapsed,
            stepTotalSeconds: storedStepTotal,
            isPaused: storedIsPaused,
            startDate: storedStartDate,
            endDate: storedEndDate
        )

        let localCandidate = scheduleCandidate ?? explicitCandidate
        if let selected = BrewingData.selectCandidate(push: pushCandidate, local: localCandidate) {
            recipeName = selected.recipeName
            stepDescription = selected.stepDescription
            currentStep = selected.currentStep
            totalSteps = selected.totalSteps
            stepElapsedSeconds = selected.stepElapsedSeconds
            stepTotalSeconds = selected.stepTotalSeconds
            isPaused = selected.isPaused
            stepTimeRange = selected.stepTimeRange
            return
        }

        let now = Date()
        recipeName = storedRecipeName
        stepDescription = storedDescription
        currentStep = max(storedCurrentStep, 1)
        totalSteps = max(storedTotalSteps, currentStep)
        stepElapsedSeconds = max(storedElapsed, 0)
        stepTotalSeconds = max(storedStepTotal, 0)
        isPaused = storedIsPaused
        stepTimeRange = now...now
    }

    private static func selectCandidate(push: Candidate?, local: Candidate?) -> Candidate? {
        // Push is the authoritative source for paused state.
        if let push, push.isPaused {
            return push
        }

        // Schedule-based local is always time-accurate and deterministic —
        // prefer it unconditionally over push candidate for running brews.
        // This ensures the lock screen advances correctly at step boundaries
        // regardless of push delivery timing, rendering budget differences
        // between the Dynamic Island and the lock screen notification area,
        // or effectiveAtMs skew from early-dispatch windows.
        if let local, local.source == .schedule {
            return local
        }

        // No schedule data available (e.g. UserDefaults missing brewStartDate);
        // arbitrate between push and explicit data using the original logic.
        guard let push else {
            return local
        }

        guard let local else {
            return push
        }

        let nowMs = Int(Date().timeIntervalSince1970 * 1000.0)
        let pushEffective = BrewingData.isPushEffective(push, nowMs: nowMs)

        if push.currentStep > local.currentStep {
            return pushEffective ? push : local
        }

        if push.currentStep == local.currentStep {
            // Monotonic same-step rule: never regress elapsed seconds when switching sources.
            if pushEffective && push.stepElapsedSeconds >= local.stepElapsedSeconds {
                return push
            }
            return local
        }

        // Keep behind-step rendering anchored to local schedule/explicit data.
        return local
    }

    private static func isPushEffective(_ push: Candidate, nowMs: Int) -> Bool {
        guard let effectiveAtMs = push.effectiveAtMs else {
            return true
        }
        return nowMs >= (effectiveAtMs - boundaryAcceptanceToleranceMs)
    }

    private static func makePushCandidate(
        state: LiveActivitiesAppAttributes.ContentState?
    ) -> Candidate? {
        guard let state,
              let recipeName = state.recipeName,
              let stepDescription = state.stepDescription,
              let currentStep = state.currentStep,
              let totalSteps = state.totalSteps,
              let stepStartDateMs = state.stepStartDateMs,
              let stepEndDateMs = state.stepEndDateMs else {
            return nil
        }

        let startDate = Date(timeIntervalSince1970: Double(stepStartDateMs) / 1000.0)
        let endDate = Date(timeIntervalSince1970: Double(stepEndDateMs) / 1000.0)
        let now = Date()

        let resolvedRange: ClosedRange<Date>
        if startDate <= endDate {
            resolvedRange = startDate...endDate
        } else {
            resolvedRange = now...now
        }

        let totalSeconds = max(0, Int(resolvedRange.upperBound.timeIntervalSince(resolvedRange.lowerBound)))
        let elapsedSeconds = min(max(0, Int(now.timeIntervalSince(resolvedRange.lowerBound))), totalSeconds)

        return Candidate(
            recipeName: recipeName,
            stepDescription: stepDescription,
            currentStep: max(currentStep, 1),
            totalSteps: max(totalSteps, max(currentStep, 1)),
            stepElapsedSeconds: elapsedSeconds,
            stepTotalSeconds: totalSeconds,
            isPaused: state.isPaused ?? false,
            stepTimeRange: resolvedRange,
            effectiveAtMs: state.effectiveAtMs ?? stepStartDateMs,
            source: .push
        )
    }

    private static func makeScheduleCandidate(
        recipeName: String,
        fallbackDescription: String,
        isPaused: Bool,
        stepDurations: [Int],
        stepDescriptions: [String],
        brewStartMs: Double
    ) -> Candidate? {
        if isPaused || stepDurations.isEmpty || brewStartMs <= 0 {
            return nil
        }

        let now = Date()
        let brewStartDate = Date(timeIntervalSince1970: brewStartMs / 1000.0)
        var elapsedTotal = max(0, Int(now.timeIntervalSince(brewStartDate)))

        let totalBrewDuration = stepDurations.reduce(0, +)
        if totalBrewDuration > 0 {
            elapsedTotal = min(elapsedTotal, totalBrewDuration)
        }

        var activeStepIndex = 0
        var activeStepElapsed = elapsedTotal

        while activeStepIndex < stepDurations.count - 1 &&
            activeStepElapsed >= stepDurations[activeStepIndex] {
            activeStepElapsed -= stepDurations[activeStepIndex]
            activeStepIndex += 1
        }

        let activeStepTotal = stepDurations[activeStepIndex]
        let boundedElapsed = min(max(activeStepElapsed, 0), activeStepTotal)

        // Compute step start deterministically from brewStartDate + cumulative prior durations.
        // This ensures the range is stable regardless of when this code evaluates,
        // so Text(timerInterval:...) and ProgressView(timerInterval:...) animate smoothly.
        let cumulativePriorDuration = stepDurations.prefix(activeStepIndex).reduce(0, +)
        let activeStepStart = brewStartDate.addingTimeInterval(TimeInterval(cumulativePriorDuration))
        let activeStepEnd = activeStepStart.addingTimeInterval(TimeInterval(activeStepTotal))

        let stepDescription: String
        if activeStepIndex < stepDescriptions.count {
            stepDescription = stepDescriptions[activeStepIndex]
        } else {
            stepDescription = fallbackDescription
        }

        return Candidate(
            recipeName: recipeName,
            stepDescription: stepDescription,
            currentStep: activeStepIndex + 1,
            totalSteps: stepDurations.count,
            stepElapsedSeconds: boundedElapsed,
            stepTotalSeconds: activeStepTotal,
            isPaused: false,
            stepTimeRange: activeStepStart...activeStepEnd,
            effectiveAtMs: nil,
            source: .schedule
        )
    }

    private static func makeExplicitCandidate(
        recipeName: String,
        stepDescription: String,
        currentStep: Int,
        totalSteps: Int,
        elapsedSeconds: Int,
        stepTotalSeconds: Int,
        isPaused: Bool,
        startDate: Date,
        endDate: Date
    ) -> Candidate {
        let now = Date()
        let resolvedRange: ClosedRange<Date>
        if startDate <= endDate {
            resolvedRange = startDate...endDate
        } else {
            resolvedRange = now...now
        }

        let totalFromRange = max(0, Int(resolvedRange.upperBound.timeIntervalSince(resolvedRange.lowerBound)))
        let resolvedStepTotal = max(stepTotalSeconds, totalFromRange)
        let resolvedElapsed = min(max(elapsedSeconds, 0), resolvedStepTotal)
        let resolvedCurrentStep = max(currentStep, 1)

        return Candidate(
            recipeName: recipeName,
            stepDescription: stepDescription,
            currentStep: resolvedCurrentStep,
            totalSteps: max(totalSteps, resolvedCurrentStep),
            stepElapsedSeconds: resolvedElapsed,
            stepTotalSeconds: resolvedStepTotal,
            isPaused: isPaused,
            stepTimeRange: resolvedRange,
            effectiveAtMs: nil,
            source: .explicit
        )
    }

    // MARK: - Explicit timeline schedule helpers

    /// Returns the wall-clock dates of every step boundary (end of each step)
    /// computed from `brewStartDate` + cumulative `stepDurationsSeconds`.
    /// Returns empty when paused or when schedule data is unavailable.
    static func stepBoundaryDates(activityId: String) -> [Date] {
        let d = defaults
        func key(_ k: String) -> String { "\(activityId)_\(k)" }

        let isPaused = (d?.integer(forKey: key("isPaused")) ?? 0) != 0
        let brewStartMs = d?.double(forKey: key("brewStartDate")) ?? 0
        guard !isPaused, brewStartMs > 0 else { return [] }

        let rawDurations = d?.array(forKey: key("stepDurationsSeconds")) ?? []
        let durations: [Int] = rawDurations.compactMap { value in
            if let intValue = value as? Int { return intValue }
            if let number = value as? NSNumber { return number.intValue }
            if let stringValue = value as? String, let intValue = Int(stringValue) { return intValue }
            return nil
        }.filter { $0 > 0 }

        guard !durations.isEmpty else { return [] }

        let brewStart = Date(timeIntervalSince1970: brewStartMs / 1000.0)
        var boundaries: [Date] = []
        var cumulative = 0
        for duration in durations {
            cumulative += duration
            boundaries.append(brewStart.addingTimeInterval(TimeInterval(cumulative)))
        }
        return boundaries
    }

    /// Builds an array of explicit dates for `TimelineView(.explicit(...))`.
    /// Dense around step boundaries + distributed catch-up dates.
    /// Hard-capped at 48 entries to stay within the iOS lock screen rendering budget.
    static func explicitScheduleDates(activityId: String) -> [Date] {
        let stepDates = stepBoundaryDates(activityId: activityId)
        let now = Date()
        let maxDates = 48

        // Adapt offsets so we keep coverage for all step boundaries within budget.
        let futureStepDates = stepDates.filter { $0 > now.addingTimeInterval(-5) }
        let offsetCandidates: [[TimeInterval]] = [
            [-1.0, 0.0, 2.0, 5.0],
            [-1.0, 0.0, 2.0],
            [0.0, 2.0],
            [0.0]
        ]
        let selectedOffsets = offsetCandidates.first(where: { offsets in
            futureStepDates.count * offsets.count <= maxDates
        }) ?? [0.0]

        var boundaryDates: [Date] = []
        for date in futureStepDates {
            for offset in selectedOffsets {
                boundaryDates.append(date.addingTimeInterval(offset))
            }
        }
        boundaryDates.sort()
        let dedupedBoundaryDates = dedupeDates(boundaryDates)

        // If boundaries alone consume the budget, prioritise earliest boundary points.
        if dedupedBoundaryDates.count >= maxDates {
            return Array(dedupedBoundaryDates.prefix(maxDates))
        }

        // Catch-up dates are spread across the remaining timeline budget so they don't crowd
        // out later boundary refreshes (which can stall lock screen progress mid-brew).
        let catchUpEnd: TimeInterval
        if let brewEnd = stepDates.last {
            catchUpEnd = max(brewEnd.timeIntervalSince(now) + 30, 30)
        } else {
            catchUpEnd = 180
        }

        let remainingBudget = maxDates - dedupedBoundaryDates.count
        var catchUpDates: [Date] = []
        if remainingBudget > 0 {
            let denominator = max(1, remainingBudget - 1)
            let catchUpStep = max(5.0, catchUpEnd / Double(denominator))
            for index in 0..<remainingBudget {
                let offset = min(Double(index) * catchUpStep, catchUpEnd)
                catchUpDates.append(now.addingTimeInterval(offset))
            }
        }

        // Merge + dedupe. Budget is preserved by construction.
        var allDates = dedupedBoundaryDates
        allDates.append(contentsOf: catchUpDates)
        allDates.sort()
        return dedupeDates(allDates)
    }

    private static func dedupeDates(_ dates: [Date]) -> [Date] {
        dates.reduce(into: []) { result, date in
            if let last = result.last, date.timeIntervalSince(last) < 0.5 { return }
            result.append(date)
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
