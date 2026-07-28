import AppKit
import LookAwayCore
import SwiftUI

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }
}

final class BreakOverlayController {
    private var windows: [NSWindow] = []
    private var confirmationWindow: NSWindow?
    private var screenObserver: NSObjectProtocol?
    private var mode: BreakMode?
    private weak var stateStore: AppStateStore?
    private weak var settingsStore: SettingsStore?
    private var onDismiss: (() -> Void)?
    private var onSnooze: (() -> Void)?

    var isShowing: Bool {
        !windows.isEmpty
    }

    func show(
        mode: BreakMode,
        stateStore: AppStateStore,
        settingsStore: SettingsStore,
        onDismiss: @escaping () -> Void,
        onSnooze: @escaping () -> Void
    ) {
        self.mode = mode
        self.stateStore = stateStore
        self.settingsStore = settingsStore
        self.onDismiss = onDismiss
        self.onSnooze = onSnooze

        rebuildWindows()

        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.rebuildWindows()
            }
        }
    }

    func hide() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }

        windows.removeAll()
        mode = nil
        stateStore = nil
        settingsStore = nil
        onDismiss = nil
        onSnooze = nil

        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }

    func showSnoozeConfirmation() {
        confirmationWindow?.close()

        let size = NSSize(width: 310, height: 84)
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 28
        )
        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentView = NSHostingView(rootView: SnoozeConfirmationView())
        panel.orderFrontRegardless()
        confirmationWindow = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self, weak panel] in
            panel?.close()
            if self?.confirmationWindow === panel {
                self?.confirmationWindow = nil
            }
        }
    }

    private func rebuildWindows() {
        guard let mode, let stateStore, let settingsStore else { return }

        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()

        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.level = .screenSaver
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.alphaValue = 0
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .ignoresCycle,
                .stationary
            ]

            window.contentView = NSHostingView(
                rootView: BreakOverlayView(
                    state: stateStore,
                    settings: settingsStore,
                    mode: mode,
                    onDismiss: { [weak self] in
                        self?.onDismiss?()
                    },
                    onSnooze: { [weak self] in
                        self?.onSnooze?()
                    }
                )
            )
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.backgroundColor = NSColor.black.cgColor

            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1
            }
            windows.append(window)
        }
    }
}

private struct SnoozeConfirmationView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.title2)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 3) {
                Text("Break snoozed")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("We’ll remind you again in 5 minutes.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 14))
        .padding(5)
    }
}
