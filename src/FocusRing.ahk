; ============================================================
; Marking the focused window
;
; Windows will colour a window's border on request, which is the
; plainest way of saying which window the keyboard is talking to.
; Needs Windows 11.
; ============================================================

; Setting() lives here, and this file does not load without it.
#Include Settings.ahk


; DWMWA_BORDER_COLOR
global DWMWA_BORDER_COLOR := 34

; Hands the border back to Windows to draw as it usually would.
global DWMWA_COLOR_DEFAULT := 0xFFFFFFFF

; COLORREF is 0x00BBGGRR, so this is a bright azure.
global FocusRingColour := 0x00FFA000

; Which window is currently wearing the ring, so that it can be
; given its ordinary border back when the focus moves on.
global RingedWindow := 0

global FocusRingCallback := 0
global FocusRingHook := 0


StartFocusRing() {
    global FocusRingCallback, FocusRingHook

    if !Setting("ShowFocusRing")
        return

    FocusRingCallback := CallbackCreate(FocusRingProc, "Fast", 7)

    ; EVENT_SYSTEM_FOREGROUND, both ends of the range
    FocusRingHook := DllCall(
        "SetWinEventHook",
        "UInt", 0x0003,
        "UInt", 0x0003,
        "Ptr", 0,
        "Ptr", FocusRingCallback,
        "UInt", 0,
        "UInt", 0,
        "UInt", 0,
        "Ptr"
    )

    OnExit(StopFocusRing)

    ; Mark whatever holds the focus already, rather than leaving
    ; nothing marked until the next time it changes.
    MarkFocused(DllCall("GetForegroundWindow", "Ptr"))
}


FocusRingProc(hook, event, hwnd, idObject, idChild, thread, time) {
    if !hwnd
        return

    ; Not every window reports this event against the window itself,
    ; some name a child object, so filtering on idObject would throw
    ; away real focus changes. Climbing to the top level window is
    ; both simpler and reliable.
    ;
    ; GA_ROOT
    root := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")

    MarkFocused(root ? root : hwnd)
}


MarkFocused(hwnd) {
    global RingedWindow, FocusRingColour, DWMWA_COLOR_DEFAULT

    if hwnd = RingedWindow
        return

    if RingedWindow
        SetBorderColour(RingedWindow, DWMWA_COLOR_DEFAULT)

    RingedWindow := 0

    if !hwnd
        return

    ; Only remember it if Windows actually took the colour, so that
    ; a window which refused one is not reset later for nothing.
    if SetBorderColour(hwnd, FocusRingColour) != 0
        return

    RingedWindow := hwnd

    ; Some apps colour their own frame as they take the focus, and
    ; land on top of this. Windows Terminal is one. Asking again a
    ; moment later settles it, twice over because a window that is
    ; still starting up takes longer to get round to it.
    ; Bound rather than a closure, because two identical closures in
    ; a loop are one and the same object, so the second SetTimer
    ; would move the first timer instead of adding a second.
    for delay in [-200, -800]
        SetTimer(Reassert.Bind(hwnd), delay)
}


Reassert(hwnd, *) {
    global RingedWindow, FocusRingColour

    ; Only while it is still the window holding the focus.
    if hwnd = RingedWindow
        SetBorderColour(hwnd, FocusRingColour)
}


; 0 back means Windows accepted the colour.
SetBorderColour(hwnd, colour) {
    global DWMWA_BORDER_COLOR

    value := colour

    try
        return DllCall(
            "dwmapi\DwmSetWindowAttribute",
            "Ptr", hwnd,
            "UInt", DWMWA_BORDER_COLOR,
            "UInt*", &value,
            "UInt", 4,
            "Int"
        )
    catch
        return -1
}


; Leaving a window recoloured after the script has gone would be
; rude, and reloading counts as going.
StopFocusRing(*) {
    global FocusRingHook, FocusRingCallback, RingedWindow, DWMWA_COLOR_DEFAULT

    if RingedWindow {
        SetBorderColour(RingedWindow, DWMWA_COLOR_DEFAULT)
        RingedWindow := 0
    }

    if FocusRingHook {
        DllCall("UnhookWinEvent", "Ptr", FocusRingHook)
        FocusRingHook := 0
    }

    if FocusRingCallback {
        CallbackFree(FocusRingCallback)
        FocusRingCallback := 0
    }
}
