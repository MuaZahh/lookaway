import LookAwayCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var state: AppStateStore

    let onTakeBreakNow: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                GroupBox("Break style") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Mode", selection: $settings.mode) {
                            ForEach(BreakMode.allCases, id: \.rawValue) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Focused includes a normal dismiss button. Strict and Extreme make breaks harder to skip.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                GroupBox("Timing") {
                    VStack(spacing: 14) {
                        numberSetting(
                            "Work interval",
                            value: $settings.workIntervalMinutes,
                            range: 1...240,
                            step: 1,
                            unit: "min"
                        )
                        numberSetting(
                            "Break length",
                            value: $settings.breakDurationSeconds,
                            range: 5...900,
                            step: 5,
                            unit: "sec"
                        )
                        numberSetting(
                            "Snooze length",
                            value: $settings.snoozeDurationMinutes,
                            range: 0.5...60,
                            step: 0.5,
                            unit: "min"
                        )
                        numberSetting(
                            "Natural break after",
                            value: $settings.idleResetMinutes,
                            range: 0.5...60,
                            step: 0.5,
                            unit: "min idle"
                        )
                    }
                    .padding(.top, 4)
                }

                GroupBox("Break screen") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Main message", text: $settings.breakTitle)
                        TextField("Second line", text: $settings.breakSubtitle)
                        Toggle("Show countdown", isOn: $settings.showCountdown)
                        Toggle("Allow Esc to snooze", isOn: $settings.allowSnooze)
                        Toggle("Play a sound when a break starts", isOn: $settings.playBreakSound)
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 4)
                }

                GroupBox("App behavior") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Start LookAway when I log in", isOn: $settings.launchAtLogin)

                        Label(state.launchAtLoginMessage, systemImage: "power")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                GroupBox("Advanced activity detection") {
                    VStack(spacing: 14) {
                        numberSetting(
                            "Recent input counts for",
                            value: $settings.activeInputWindowSeconds,
                            range: 0.5...60,
                            step: 0.5,
                            unit: "sec"
                        )
                        numberSetting(
                            "Emergency shortcut hold",
                            value: $settings.emergencyHoldSeconds,
                            range: 1...30,
                            step: 1,
                            unit: "sec"
                        )
                    }
                    .padding(.top, 4)
                }

                footer
            }
            .padding(22)
        }
        .frame(minWidth: 560, idealWidth: 620, minHeight: 540, idealHeight: 680)
    }

    private var header: some View {
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
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: onTakeBreakNow) {
                Label("Test Break", systemImage: "pause.circle")
            }
            .disabled(!settings.isEnabled)

            Button {
                settings.resetDefaults()
            } label: {
                Label("Reset Defaults", systemImage: "arrow.counterclockwise")
            }

            Spacer()

            statsView
        }
    }

    private func numberSetting(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(formatted(value.wrappedValue))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(minWidth: 48, alignment: .leading)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
    }

    private func formatted(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
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
