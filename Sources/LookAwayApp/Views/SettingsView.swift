import LookAwayCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var state: AppStateStore

    let onTakeBreakNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LookAway")
                        .font(.title2.weight(.semibold))
                    Text(state.statusText)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Enabled", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
            }

            Divider()

            Picker("Mode", selection: $settings.mode) {
                ForEach(BreakMode.allCases, id: \.rawValue) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                GridRow {
                    Text("Work")
                    Stepper("\(Int(settings.workIntervalMinutes)) min", value: $settings.workIntervalMinutes, in: 5...90, step: 5)
                }

                GridRow {
                    Text("Break")
                    Stepper("\(Int(settings.breakDurationSeconds)) sec", value: $settings.breakDurationSeconds, in: 20...300, step: 10)
                }

                GridRow {
                    Text("Idle reset")
                    Stepper("\(Int(settings.idleResetMinutes)) min", value: $settings.idleResetMinutes, in: 1...15, step: 1)
                }

                GridRow {
                    Text("Input window")
                    Stepper("\(settings.activeInputWindowSeconds, specifier: "%.1f") sec", value: $settings.activeInputWindowSeconds, in: 0.5...10, step: 0.5)
                }

                GridRow {
                    Text("Emergency hold")
                    Stepper("\(Int(settings.emergencyHoldSeconds)) sec", value: $settings.emergencyHoldSeconds, in: 3...15, step: 1)
                }
            }

            Divider()

            Label(state.launchAtLoginMessage, systemImage: "power")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button(action: onTakeBreakNow) {
                    Label("Start Break", systemImage: "pause.circle")
                }
                .disabled(!settings.isEnabled)

                Button {
                    settings.resetDefaults()
                } label: {
                    Label("Defaults", systemImage: "arrow.counterclockwise")
                }

                Spacer()

                statsView
            }
        }
        .padding(22)
        .frame(width: 520)
    }

    private var statsView: some View {
        HStack(spacing: 12) {
            stat("Done", state.completedBreaks)
            stat("Idle", state.naturalBreaks)
            stat("Skipped", state.skippedBreaks)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func stat(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.primary)
            Text(title)
        }
    }
}
