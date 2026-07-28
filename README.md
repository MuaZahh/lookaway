# LookAway

LookAway is a native macOS menu-bar app that enforces eye breaks after active computer use. It tracks input activity, counts natural idle breaks, and can cover every display while leaving system audio and microphone behavior untouched.

## Run

Use the Codex Run action, or run:

```sh
./script/build_and_run.sh
```

The script builds a SwiftPM app bundle at `dist/LookAway.app` and launches it as a menu-bar app.
On first launch, LookAway registers itself to open when you log in. If macOS asks
for approval, allow it under System Settings → General → Login Items.

## Verify

Run the pure timing edge-case checks:

```sh
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run --disable-index-store LookAwayCoreChecks
```

Build and launch-check the app:

```sh
./script/build_and_run.sh --verify
```

## Defaults

- Work interval: 25 minutes of active use
- Break duration: 60 seconds
- Idle reset: 2 minutes
- Mode: Strict
- Emergency override: hold `Cmd+Option+Esc` for 5 seconds
- During a break: press `Esc` to snooze it for 5 minutes

Modes include Gentle, Focused, Strict, Extreme, and Recovery.
