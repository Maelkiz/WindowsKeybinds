; ============================================================
; The start menu
; ============================================================

; Setting() lives here, and this file does not load without it.
#Include Settings.ahk


; The Windows key itself, which keeps working even with the key
; unbound below: AutoHotkey does not let a script's own keystrokes
; set off that same script's hotkeys, so the swallowing never sees
; this one.
;
; Not Ctrl+Esc, which opens the start menu when pressed by hand but
; is ignored when a script sends it.
OpenStartMenu() {
    Send "{LWin}"
}


; Windows opens the start menu when the Windows key goes up with
; nothing else having been pressed in between. Sending a key that
; means nothing to anything, while the Windows key is down, makes
; it look like a combination instead, so no start menu.
;
; Deliberately done with ~, which passes the Windows key through
; untouched. Claiming the key instead would stop Super+<key>
; combinations reaching their hotkeys.
UnbindStartMenuKey() {
    if !Setting("UnbindStartMenu")
        return

    for key in ["~LWin", "~RWin"] {
        try
            Hotkey(key, SwallowStartMenu)
    }
}


; vk07 is undefined, so nothing acts on it.
SwallowStartMenu(*) {
    Send "{Blind}{vk07}"
}
