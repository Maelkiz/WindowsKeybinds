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

; How often to check the ring is where it belongs.
global FocusRingInterval := 250

; Which window is currently wearing the ring, so that it can be
; given its ordinary border back when the focus moves on.
global RingedWindow := 0

global FocusRingCallback := 0
global FocusRingHook := 0


StartFocusRing() {
    global FocusRingCallback, FocusRingHook, FocusRingInterval

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

    SetTimer(SyncFocusRing, FocusRingInterval)

    ; Mark whatever holds the focus already, rather than leaving
    ; nothing marked until the next time it changes.
    SyncFocusRing()
}


; The hook is what makes the ring keep up with the eye. It cannot
; be relied on alone though: alt-tab does not always announce the
; window it lands on, and some apps colour their own frame a moment
; after taking the focus, painting over this. So the foreground
; window is also checked at a steady interval, which covers both.
SyncFocusRing() {
    global RingedWindow, FocusRingColour

    hwnd := ForegroundWindow()

    if !hwnd
        return

    if hwnd != RingedWindow {
        MarkFocused(hwnd)
        return
    }

    ; Same window as last time, so just make sure the colour on it
    ; is still the one we asked for.
    SetBorderColour(hwnd, FocusRingColour)
}


FocusRingProc(hook, event, hwnd, idObject, idChild, thread, time) {
    if !hwnd
        return

    MarkFocused(TopLevel(hwnd))
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
    if SetBorderColour(hwnd, FocusRingColour) = 0
        RingedWindow := hwnd
}


ForegroundWindow() {
    hwnd := DllCall("GetForegroundWindow", "Ptr")

    return hwnd ? TopLevel(hwnd) : 0
}


; Not every window announces itself by its own handle, some name a
; child object, so the top level owner is what gets the ring.
TopLevel(hwnd) {
    ; GA_ROOT
    root := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 2, "Ptr")

    return root ? root : hwnd
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

    SetTimer(SyncFocusRing, 0)

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
