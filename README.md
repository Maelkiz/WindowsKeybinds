# Windows Shortcuts

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

## Setup Instructions

### 1. Clone this repository:
```bash
git clone https://github.com/Maelkiz/WindowsShortcuts.git
```

### 2. Ensure the AutoHotkey scripts run on startup:
Open a PowerShell terminal with administrator rights, navigate to the repository, and run the PowerShell script like so:
```pwsh
.\CreateStartupShortcuts.ps1
```

### 3. Set up virtual desktops
If you want to use the `Super`+`<number>` and `Super`+`Shift`+`<number>` shortcuts, press `Super`+`Tab` and ensure you have 10 virtual desktops set up (fewer than 10 will also work).
