# Notes for coding agents

## Do not test this project by driving the machine

Everything here acts on global, single-instance state: which virtual desktop
is in front, which window has focus, where a window lives. There is exactly
one of that state on the machine, and the person who asked for the change is
using it at the same time.

That cuts both ways, and both directions have already bitten:

- Switching desktops, launching apps, activating or hiding windows, or
  sending hotkeys yanks the user out of whatever they were doing. Doing it
  repeatedly while iterating is genuinely disruptive, not a minor cost.
- Their ordinary use moves the same state underneath the test. A desktop
  change in a log is then unattributable: it could be the code, or it could
  be them reaching for another window. Results gathered that way look like
  evidence and are not.

So do not write scripts that switch desktops, open or close the user's
applications, or activate their windows in order to check whether something
works. Hand the testing to the user instead.

### Ask for a manual test

Give a short, specific checklist: the steps to perform, the desktop to stand
on, and what should happen. Something like:

> From desktop 1, open Outlook. Expected: its window opens on desktop 4.
> Then press Super+1 a few times. Expected: you stay on desktop 1.

This is faster than an automated attempt, costs a fraction of the tokens, and
the answer is trustworthy because nothing else was moving at the time.

### What is still fine to do without asking

- Reading files, config, and git history.
- Passive, read-only inspection: which processes exist, window classes,
  titles, owners, a window's current desktop number.
- Passive event logging that observes and moves nothing.
- Synthetic probes that create a window of their own, off-screen, and watch
  only that window. This is how the difference between the window creation
  and window shown events was established without touching anything the user
  owned.

The line is whether the machine's shared state changes. Observing is fine.
Steering is not.

## Restarting the keybinds is not a free action

`scripts/Restart.ps1` restarts the script that owns the user's keyboard. A
bad version does not fail quietly:

- An AutoHotkey error opens a modal dialog and the script stops handling
  events, so the keybinds are simply gone until it is dismissed. After any
  restart, check for an error dialog (`ahk_class #32770` in the script's
  process) rather than assuming a running process means a working one.
- A window rule that misfires can move the user between desktops while they
  are typing.

Restart with the user's knowledge, and if anything looks wrong, revert to the
committed version and restart again before investigating further. Getting
them back to a known-good state comes first; the diagnosis can wait.

## Test against the user's config, not the defaults

`src/config.default.ini` is a template. The live config is found by
`FindConfigPath()` in `src/ConfigPaths.ahk`, normally
`%USERPROFILE%\.config\WindowsKeybinds\config.ini`, and its settings can
invert how a change behaves.

`FollowManualMoves` is the one to watch. With it on, sending a window to
another desktop also takes the user there, so the same keypress lands them
somewhere different depending on the setting. The script's default is `true`
and the live config sets it to `false`; reasoning from either one alone will
get it wrong half the time.

Read the live config before predicting what a change will do.

## Virtual desktop events are not uniform across applications

Behaviour measured on one window does not generalise. Chrome emits a hide
event when you leave the desktop it is on; a plain AutoHotkey window and
Outlook's main window do not. A rule built on "a hide means the window gave up
its place" therefore held for Outlook and broke badly for Chrome.

Cloaking and hiding also look alike from the outside. Both report a desktop
number of `-1`, so that number cannot be used to tell them apart.

If a change depends on which events a window emits, check it against several
real applications before relying on it.
