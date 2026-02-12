import ActivityKit
import WidgetKit
import SwiftUI

@available(iOSApplicationExtension 16.1, *)
struct BrewingTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // MARK: - Lock Screen / StandBy View
            LockScreenView(data: BrewingData(activityId: context.attributes.id.uuidString))
                .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            let data = BrewingData(activityId: context.attributes.id.uuidString)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
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

                DynamicIslandExpandedRegion(.trailing) {
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

                DynamicIslandExpandedRegion(.center) {
                    Text(data.recipeName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        Text(data.stepDescription)
                            .font(.caption2)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ProgressView(value: data.progress)
                            .tint(.brown)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading (step indicator)
                Text(data.stepLabel)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.brown)
            } compactTrailing: {
                // MARK: - Compact Trailing (timer)
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
            } minimal: {
                // MARK: - Minimal (just timer)
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

// MARK: - Lock Screen View

@available(iOSApplicationExtension 16.1, *)
struct LockScreenView: View {
    let data: BrewingData

    var body: some View {
        VStack(spacing: 8) {
            // Top row: recipe name + timer
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

                ProgressView(value: data.progress)
                    .tint(.brown)
            }
        }
        .padding(16)
    }
}
