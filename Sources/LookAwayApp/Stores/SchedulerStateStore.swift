import Foundation
import LookAwayCore

final class SchedulerStateStore {
    private let defaults: UserDefaults
    private let key = "breakSchedulerState"
    private var lastSavedState: BreakSchedulerPersistedState?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> BreakSchedulerPersistedState? {
        guard
            let data = defaults.data(forKey: key),
            let state = try? JSONDecoder().decode(BreakSchedulerPersistedState.self, from: data)
        else {
            return nil
        }

        lastSavedState = state
        return state
    }

    func save(_ state: BreakSchedulerPersistedState) {
        guard state != lastSavedState else { return }
        guard let data = try? JSONEncoder().encode(state) else { return }

        defaults.set(data, forKey: key)
        lastSavedState = state
    }
}
