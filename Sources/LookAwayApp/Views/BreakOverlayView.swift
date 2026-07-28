import LookAwayCore
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

                Text(TimeFormatter.clock(state.snapshot.breakRemaining))
                    .font(.system(size: mode.usesBlackout ? 34 : 76, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(mode.usesBlackout ? 0.2 : 0.96))
                    .monospacedDigit()

                if !mode.usesBlackout {
                    VStack(spacing: 8) {
                        Text("Look far away")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Blink slowly")
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

                Button(action: onSnooze) {
                    Label("Remind Me in 5 Minutes", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .foregroundStyle(.white)
                .keyboardShortcut(.cancelAction)

                Text("Press Esc to snooze")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(40)
        }
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
