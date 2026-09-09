; Setting() lives here, and this file does not load without it.
#Include Settings.ahk


vda := DllCall(
    "LoadLibrary",
    "Str", A_ScriptDir "\VirtualDesktopAccessor.dll",
    "Ptr"
)

CurrentDesktop() {
    return DllCall("VirtualDesktopAccessor\GetCurrentDesktopNumber", "Int")
}


GoToDesktop(n) {
    DllCall(
        "VirtualDesktopAccessor\GoToDesktopNumber",
        "Int", n - 1
    )

    FocusDesktop(n - 1)
}


; Switching desktop leaves the keyboard focus behind, on a
; window that is no longer on screen. Anything typed then goes
; to a window you cannot see, so focus is moved to something
; that is actually on the desktop just arrived at.
FocusDesktop(index) {
    ; The switch is not instant, and windows stay cloaked until
    ; it has finished, so wait for it to land first.
    deadline := A_TickCount + 500

    while A_TickCount < deadline {
        if CurrentDesktop() = index
            break

        Sleep 20
    }

    hwnd := TopWindowOnDesktop(index)

    ; An empty desktop still needs the focus taking off the
    ; window we came from, so hand it to the desktop itself.
    if !hwnd
        hwnd := WinExist("ahk_class Progman")

    if hwnd {
        try
            WinActivate("ahk_id " hwnd)
    }
}


; The frontmost ordinary window on the given desktop, or 0.
TopWindowOnDesktop(index) {
    ; Windows sitting on another desktop are cloaked rather than
    ; hidden, so they have to be detectable for this to see them.
    previous := A_DetectHiddenWindows
    DetectHiddenWindows true

    found := 0

    ; WinGetList is in Z-order, so the first match is the window
    ; that was most recently in front on that desktop.
    for hwnd in WinGetList() {
        if DllCall("VirtualDesktopAccessor\GetWindowDesktopNumber", "Ptr", hwnd, "Int") != index
            continue

        if !DllCall("IsWindowVisible", "Ptr", hwnd, "Int")
            continue

        ; 4 is GW_OWNER. Dialogs and palettes are owned, and are
        ; not what you want the focus landing on.
        if DllCall("GetWindow", "Ptr", hwnd, "UInt", 4, "Ptr")
            continue

        ; 0x80 is WS_EX_TOOLWINDOW, which alt-tab skips too.
        if WinGetExStyle("ahk_id " hwnd) & 0x80
            continue

        if WinGetTitle("ahk_id " hwnd) = ""
            continue

        found := hwnd
        break
    }

    DetectHiddenWindows previous

    return found
}


MoveWindowToDesktop(n) {
    hwnd := WinExist("A")

    if !hwnd
        return

    from := CurrentDesktop()

    DllCall(
        "VirtualDesktopAccessor\MoveWindowToDesktopNumber",
        "Ptr", hwnd,
        "Int", n - 1
    )

    if Setting("FollowManualMoves") {
        GoToDesktop(n)

        ; Land on the window that was sent over, rather than on
        ; whatever else happened to be in front there.
        try
            WinActivate("ahk_id " hwnd)

        return
    }

    ; Staying behind, but the window that had the focus has
    ; just left, so the focus needs somewhere else to go.
    if CurrentDesktop() != from
        DllCall("VirtualDesktopAccessor\GoToDesktopNumber", "Int", from)

    FocusDesktop(from)
}
