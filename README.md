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

## Running it

Use the Codex Run action, or run:

```sh
./script/build_and_run.sh
```

That builds `dist/LookAway.app` and launches it in your menu bar.

The first time you open it, LookAway asks macOS to start it whenever you log in.
If macOS needs you to approve that, go to:

**System Settings → General → Login Items**

## The normal setup

- Work for 25 minutes
- Look away for 60 seconds
- Press **Esc** to snooze a break for 5 minutes
- Hold **Cmd + Option + Esc** for 5 seconds if you really need the emergency exit

There are also Gentle, Focused, Strict, Extreme, and Recovery modes depending on
how aggressively you want the app to bother you.

## Checking that it works

Run the timer checks:

```sh
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run --disable-index-store LookAwayCoreChecks
```

Or build it and make sure the app launches:

```sh
./script/build_and_run.sh --verify
```
