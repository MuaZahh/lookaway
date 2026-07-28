public enum BreakMode: String, CaseIterable, Codable, Sendable {
    case gentle
    case focused
    case strict
    case extreme
    case recovery

    public var displayName: String {
        switch self {
        case .gentle: "Gentle"
        case .focused: "Focused"
        case .strict: "Strict"
        case .extreme: "Extreme"
        case .recovery: "Recovery"
        }
    }

    public var showsOverlay: Bool {
        self != .gentle
    }

    public var allowsVisibleDismiss: Bool {
        self == .focused
    }

    public var usesBlackout: Bool {
        self == .extreme
    }
}
