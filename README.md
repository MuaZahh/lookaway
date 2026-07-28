# LookAway

I made this because I used to sit on my laptop for **four hours straight**
without looking away once. My eyes would feel awful afterward, but when I was
locked in, I would completely forget to take a break.

So yeah, LookAway is basically a tiny macOS app that makes me stop for a minute.
It sits in the menu bar, keeps track of how long I have actually been using my
Mac, and puts a break screen over my displays when it is time to look somewhere
else.

## What it does

- Reminds you after 25 minutes of active laptop use
- Gives you a 60-second eye break
- Notices when you naturally walk away, so it does not annoy you for no reason
- Works across every connected display
- Leaves your audio and microphone alone
- Saves your timer if the app or Mac restarts
- Starts again when you log back into your Mac

If the reminder catches you in the middle of a game, call, or something
important, just press **Esc**. It gets out of the way, shows a quick confirmation,
and comes back five minutes later.

## Install from a fresh clone

You need macOS 14 or newer and Apple's free Command Line Tools. If you do not
already have them, run:

```sh
xcode-select --install
```

Then clone, install, and open LookAway:

```sh
git clone https://github.com/MuaZahh/lookaway.git
cd lookaway
./script/install.sh
```

The installer makes a release build, copies it to `~/Applications/LookAway.app`,
and opens it. No Xcode project setup is needed.

The first time you open it, LookAway asks macOS to start it whenever you log in.
If macOS needs you to approve that, go to:

**System Settings → General → Login Items**

## Change basically everything

Click the eye icon in the menu bar and choose **Settings**. You can change:

- Work, break, snooze, and natural-idle timing
- The break-screen title and second line
- Break mode
- Countdown visibility
- Break sound
- Whether Esc can snooze
- Whether LookAway starts at login
- Activity detection and emergency-shortcut timing

Everything is saved automatically. Pausing is intentionally temporary, so
LookAway turns itself back on after you relaunch it or restart your Mac.

## Run without installing

Use the Codex Run action, or run:

```sh
./script/build_and_run.sh
```

That makes a development build at `dist/LookAway.app` and opens it.

## Checking that it works

Run the timer checks:

```sh
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run --disable-index-store LookAwayCoreChecks
```

Or build it and make sure the app launches:

```sh
./script/build_and_run.sh --verify
```
