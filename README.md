# Windows Keybindings

Uses AutoHotkey v2 to make a better keyboard-first experience on Windows. 

| Keybind | Action |
|---------|--------|
| `Super`+`Enter` | Launch a new terminal window |
| `Super`+`B` | Launch a new browser window |
| `Super`+`F` | Toggle window maximization state |
| `Super`+`Q` | Close window |
| `Super`+`C` | Center window |
| `Super`+`<number>` | Switch to virtual desktop of said number |
| `Super`+`Shift`+`<number>` | Move window to virtual desktop of said number |
| `Super`+`F12` | Toggle visibility of desktop icons (hide your mess instead of cleaning it up) |

Also unbinds `F1` from launching the help browser.

All of the above are defaults, and can be configured. See [Configuration](#configuration).

## Setup Instructions

### 1. Clone this repository:
```bash
git clone https://github.com/Maelkiz/WindowsKeybinds.git
```

### 2. Ensure the AutoHotkey scripts run on startup:
Run the PowerShell script either by double-clicking it in the explorer or from a terminal like so:
```pwsh
.\CreateStartupShortcuts.ps1
```

### 3. Set up virtual desktops
If you want to use the `Super`+`<number>` and `Super`+`Shift`+`<number>` keybinds, press `Super`+`Tab` and ensure you have 10 virtual desktops set up (fewer than 10 will also work).

## Configuration

On first run, a config file is created at:

```
%USERPROFILE%\.config\WindowsKeybinds\config.ini
```

It lives outside the repository so that `git pull` never conflicts with your
own keybinds. [config.default.ini](config.default.ini) is the template it is
copied from, and documents every key name and action inline.

These locations are searched in order, and the first one that exists is used:

1. The path in the `WINDOWSKEYBINDS_CONFIG` environment variable
2. `%USERPROFILE%\.config\WindowsKeybinds\config.ini`
3. `%APPDATA%\WindowsKeybinds\config.ini`
4. `config.ini` next to the scripts, for a portable install

Run `.\Refresh.ps1` to pick up your changes.

### Keybinds

Keys are written as `Modifier+Modifier+Key`, and actions are named:

```ini
[Keybinds]
Super+C = CenterWindow
Super+Shift+1 = MoveWindowToDesktop 1
Ctrl+Alt+T = LaunchTerminal

; Stops a key doing anything at all
F1 = None
```

Modifiers are `Super` (or `Win`), `Ctrl`, `Alt` and `Shift`.

Most keys are written as you would say them: `Enter`, `Space`, `Tab`, `Esc`,
`F1` to `F24`, `Left`, `Home`, `PgUp`, `Numpad0`, letters and digits. Keys that
cannot be written literally in an ini file, or that read better spelled out,
have names: `Plus`, `Equals`, `Minus`, `Comma`, `Period`, `Semicolon`, `Quote`,
`Slash`, `Backslash`, `LeftBracket`, `RightBracket` and `Backtick`. These name
physical keys, so `Plus` and `Equals` are the same key — write
`Super+Shift+Equals` if you want the shifted symbol.

| Action | Argument |
|--------|----------|
| `CenterWindow` | |
| `CloseWindow` | |
| `LaunchBrowser` | |
| `LaunchTerminal` | |
| `ToggleMaximization` | |
| `ToggleDesktopIcons` | |
| `GoToDesktop` | desktop number |
| `MoveWindowToDesktop` | desktop number |
| `None` | |

### Window rules

Windows of a given process can be sent to a given virtual desktop as they open:

```ini
[WindowRules]
chrome.exe = 2
Code.exe = 3
```

### When something is wrong

Anything the config file gets wrong — an unknown action, a misspelled key, a
key bound twice — is reported in a tray notification at startup, naming the
line at fault. Every other keybind still works, so a typo never leaves you
without a keyboard.

### Adding your own actions

Actions are looked up by name in a table in [Actions.ahk](Actions.ahk). Write a
function in a file of its own, `#Include` it from
[WindowsKeybinds.ahk](WindowsKeybinds.ahk), and add one `RegisterAction` line
to make it available to the config file.
