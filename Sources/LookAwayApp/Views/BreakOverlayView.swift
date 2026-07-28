import LookAwayCore
import Foundation
import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var state: AppStateStore
    @ObservedObject var settings: SettingsStore

    let mode: BreakMode
    let onDismiss: () -> Void
    let onSnooze: () -> Void

    var body: some View {
        ZStack {
            background

            VStack(spacing: 22) {
                Image(systemName: mode.usesBlackout ? "moon.zzz.fill" : "eye.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white.opacity(mode.usesBlackout ? 0.18 : 0.9))

                if settings.showCountdown {
                    Text(TimeFormatter.clock(state.snapshot.breakRemaining))
                        .font(.system(size: mode.usesBlackout ? 34 : 76, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(mode.usesBlackout ? 0.2 : 0.96))
                        .monospacedDigit()
                }

                if !mode.usesBlackout {
                    VStack(spacing: 8) {
                        Text(settings.breakTitle)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(settings.breakSubtitle)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }

                if state.snapshot.isEmergencyOverrideActive {
                    ProgressView(
                        value: state.snapshot.emergencyOverrideProgress,
                        total: settings.emergencyHoldSeconds
                    )
                    .progressViewStyle(.linear)
                    .frame(width: 220)
                    .tint(.white.opacity(0.75))
                }

                if mode.allowsVisibleDismiss {
                    Button(action: onDismiss) {
                        Label("Dismiss", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 8)
                }

                if settings.allowSnooze {
                    Button(action: onSnooze) {
                        Label(
                            "Remind Me in \(formattedSnoozeDuration)",
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .foregroundStyle(.white)
                    .keyboardShortcut(.cancelAction)

                    Text("Press Esc to snooze")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(40)
        }
    }

    private var formattedSnoozeDuration: String {
        let minutes = settings.snoozeDurationMinutes
        if minutes.rounded() == minutes {
            return "\(Int(minutes)) min"
        }
        return String(format: "%.1f min", minutes)
    }

    @ViewBuilder
    private var background: some View {
        if mode.usesBlackout {
            Color.black
        } else {
            Color(red: 0.015, green: 0.018, blue: 0.02)
        }
    }
}
