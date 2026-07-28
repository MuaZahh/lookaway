import AppKit
import Carbon
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: Int

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        ShortcutRecorderNSView(
            keyCode: keyCode,
            modifiers: modifiers,
            onChange: { keyCode, modifiers in
                self.keyCode = keyCode
                self.modifiers = modifiers
            }
        )
    }

    func updateNSView(_ view: ShortcutRecorderNSView, context: Context) {
        view.update(keyCode: keyCode, modifiers: modifiers)
    }
}

final class ShortcutRecorderNSView: NSView {
    private let label = NSTextField(labelWithString: "")
    private var keyCode: Int
    private var modifiers: Int
    private let onChange: (Int, Int) -> Void
    private var isRecording = false

    init(
        keyCode: Int,
        modifiers: Int,
        onChange: @escaping (Int, Int) -> Void
    ) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.onChange = onChange
        super.init(frame: .zero)

        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        label.alignment = .center
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        setAccessibilityLabel("Extension keyboard shortcut")
        setAccessibilityRole(.button)
        updateLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 150, height: 30)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        isRecording = true
        label.stringValue = "Press shortcut…"
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        return true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        layer?.borderColor = NSColor.separatorColor.cgColor
        updateLabel()
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            window?.makeFirstResponder(nil)
            return
        }

        let newModifiers = ShortcutFormatter.carbonModifiers(from: event.modifierFlags)
        guard ShortcutFormatter.hasSafeModifier(newModifiers) else {
            NSSound.beep()
            label.stringValue = "Add ⌘, ⌥, or ⌃"
            return
        }

        keyCode = Int(event.keyCode)
        modifiers = newModifiers
        onChange(keyCode, modifiers)
        window?.makeFirstResponder(nil)
    }

    func update(keyCode: Int, modifiers: Int) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        if !isRecording {
            updateLabel()
        }
    }

    private func updateLabel() {
        label.stringValue = ShortcutFormatter.display(
            keyCode: keyCode,
            modifiers: modifiers
        )
        setAccessibilityValue(label.stringValue)
    }
}
