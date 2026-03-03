import ActivityKit
import WidgetKit
import SwiftUI
import os

@available(iOSApplicationExtension 16.1, *)
struct BrewingTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // MARK: - Lock Screen / StandBy View
            let activityId = context.attributes.id.uuidString
            LockScreenView(
                activityId: activityId,
                state: context.state
            )
                .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            let activityId = context.attributes.id.uuidString
            let scheduleDates = BrewingData.explicitScheduleDates(activityId: activityId)

            return DynamicIsland {
                // MARK: - Expanded Leading (app icon + step label)
                DynamicIslandExpandedRegion(.leading) {
                    TimelineView(.explicit(scheduleDates)) { timelineContext in
                        let data = BrewingData(activityId: activityId, state: context.state, date: timelineContext.date)
                        VStack(alignment: .leading, spacing: 2) {
                            Image("AppIconSmall")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(data.stepLabel)
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                    }
                }

                // MARK: - Expanded Trailing (timer countdown)
                DynamicIslandExpandedRegion(.trailing) {
                    TimelineView(.explicit(scheduleDates)) { timelineContext in
                        let data = BrewingData(activityId: activityId, state: context.state, date: timelineContext.date)
                        VStack(alignment: .trailing, spacing: 2) {
                            if data.isPaused {
                                Image(systemName: "pause.fill")
                                    .font(.title3)
                            } else {
                                Text(timerInterval: data.stepTimeRange, countsDown: true)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .frame(width: 56, alignment: .trailing)
                            }
                        }
                    }
                }

                // MARK: - Expanded Center (recipe name)
                DynamicIslandExpandedRegion(.center) {
                    TimelineView(.explicit(scheduleDates)) { timelineContext in
                        let data = BrewingData(activityId: activityId, state: context.state, date: timelineContext.date)
                        Text(data.recipeName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }

                // MARK: - Expanded Bottom (description + progress bar)
                DynamicIslandExpandedRegion(.bottom) {
                    TimelineView(.explicit(scheduleDates)) { timelineContext in
                        let data = BrewingData(activityId: activityId, state: context.state, date: timelineContext.date)
                        VStack(spacing: 6) {
                            Text(data.stepDescription)
                                .font(.caption2)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if data.isPaused {
                                ProgressView(value: data.progress)
                                    .tint(.brown)
                            } else {
                                ProgressView(timerInterval: data.stepTimeRange, countsDown: false)
                                    .tint(.brown)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                // MARK: - Compact Leading (step indicator)
                TimelineView(.explicit(scheduleDates)) { timelineContext in
                    let data = BrewingData(activityId: activityId, state: context.state, date: timelineContext.date)
                    Text(data.stepLabel)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.brown)
                }
            } compactTrailing: {
                // MARK: - Compact Trailing (timer)
                TimelineView(.explicit(scheduleDates)) { timelineContext in
                    let data = BrewingData(activityId: activityId, state: context.state, date: timelineContext.date)
                    if data.isPaused {
                        Image(systemName: "pause.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(timerInterval: data.stepTimeRange, countsDown: true)
                            .monospacedDigit()
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .frame(width: 40)
                    }
                }
            } minimal: {
                // MARK: - Minimal (just timer)
                TimelineView(.explicit(scheduleDates)) { timelineContext in
                    let data = BrewingData(activityId: activityId, state: context.state, date: timelineContext.date)
                    if data.isPaused {
                        Image(systemName: "pause.fill")
                            .font(.caption2)
                    } else {
                        Text(timerInterval: data.stepTimeRange, countsDown: true)
                            .monospacedDigit()
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - Lock Screen View

private let lockScreenLogger = Logger(subsystem: "group.timer.coffee", category: "LockScreen")

@available(iOSApplicationExtension 16.1, *)
struct LockScreenView: View {
    let activityId: String
    let state: LiveActivitiesAppAttributes.ContentState

    var body: some View {
        // Lock Screen TimelineView schedules are unreliable for Live Activities;
        // derive state from wall clock whenever iOS re-renders this view.
        lockScreenContent(date: Date())
    }

    @ViewBuilder
    private func lockScreenContent(date: Date) -> some View {
        let data = BrewingData(activityId: activityId, state: state, date: date)
        let _ = lockScreenLogger.info(
            "[LockScreen] render step=\(data.currentStep)/\(data.totalSteps) desc='\(data.stepDescription)' rangeStart=\(data.stepTimeRange.lowerBound.timeIntervalSince1970, format: .fixed(precision: 3)) rangeEnd=\(data.stepTimeRange.upperBound.timeIntervalSince1970, format: .fixed(precision: 3)) now=\(date.timeIntervalSince1970, format: .fixed(precision: 3)) paused=\(data.isPaused)"
        )
        VStack(spacing: 8) {
            // Top row: recipe name + countdown timer
            HStack {
                HStack(spacing: 6) {
                    Image("AppIconSmall")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Text(data.recipeName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                Spacer()

                if data.isPaused {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                        Text("Paused")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Text(timerInterval: data.stepTimeRange, countsDown: true)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }

            // Step description
            Text(data.stepDescription)
                .font(.caption)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)

            // Bottom row: step indicator + progress
            HStack(spacing: 8) {
                Text("Step \(data.stepLabel)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if data.isPaused {
                    ProgressView(value: data.progress)
                        .tint(.brown)
                } else {
                    ProgressView(timerInterval: data.stepTimeRange, countsDown: false)
                        .tint(.brown)
                }
            }
        }
        .padding(16)
    }
}
