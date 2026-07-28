# LookAway

I made this after realizing I was using my laptop for **four hours straight**
without taking a proper break. My eyes felt horrible afterward, and it kept
happening because I never noticed how much time had gone by.

LookAway is a small Mac menu-bar app that keeps track of that for me. Once I have
been using my Mac for a while, it puts up a break screen and reminds me to look
away for a bit.

## What it does

- Reminds you after you have actually been using your laptop for a while
- Gives you a short break from the screen
- Notices when you get up and walk away, so it does not bug you for no reason
- Covers all your screens but leaves your audio and microphone alone
- Remembers your timer if the app or your Mac restarts
- Opens again when you log back into your Mac
- Gives you a macOS notification before the break starts
- Lets you pick a global shortcut to add more time

If it pops up while you are playing a game, on a call, or doing something
important, press **Esc** and it will come back a few minutes later. You can
change how long that snooze is in Settings.

By default, LookAway also gives you a macOS notification one minute before the
break. Press **Cmd + Option + S** to add your snooze time without leaving
whatever app you are using. Both the warning time and shortcut can be changed.

## Install it

You need macOS 14 or newer. If you do not have Apple's Command Line Tools yet,
run this first:

```sh
xcode-select --install
```

Then:

```sh
git clone https://github.com/MuaZahh/lookaway.git
cd lookaway
./script/install.sh
```

The installer makes a release build, copies it to `~/Applications/LookAway.app`,
and opens it. That is it—no Xcode project setup needed.

macOS might ask you to approve opening LookAway at login. If it does, go to:

**System Settings → General → Login Items**

## Make it work how you want

Click the little eye in the menu bar and choose **Settings**. You can change:

- Work, break, snooze, and natural-idle timing
- The break-screen title and second line
- Break mode
- Countdown visibility
- Break sound
- Whether Esc can snooze
- How early the macOS warning appears
- Your global “add more time” keyboard shortcut
- Whether LookAway starts at login
- Activity detection and emergency-shortcut timing

It all saves automatically. Pausing is temporary, so LookAway turns itself back
on if you relaunch it or restart your Mac.

## Just run it without installing

If you only want to try it:

```sh
./script/build_and_run.sh
```

That makes a development build and opens it.

## Tests

Timer checks:

```sh
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run --disable-index-store LookAwayCoreChecks
```

Build and launch check:

```sh
./script/build_and_run.sh --verify
```
