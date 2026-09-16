; ============================================================
; Rules
; ============================================================

; Setting() and CenterWindow() live here, and this file does not
; load without them.
#Include Settings.ahk
#Include CenterWindow.ahk

global Rules := Map()

AddRule(processName, desktop) {
    global Rules
    Rules[StrLower(processName)] := desktop
}


; ============================================================
; Window Event Hook
; ============================================================

; EVENT_OBJECT_CREATE
EVENT_OBJECT_CREATE := 0x8000

; EVENT_OBJECT_DESTROY
global EVENT_OBJECT_DESTROY := 0x8001

; EVENT_OBJECT_SHOW
global EVENT_OBJECT_SHOW := 0x8002

; OBJID_WINDOW
OBJID_WINDOW := 0

; Handles already handed to ApplyRule and, if it applies, centered.
; An app that closes to the tray keeps its handle and only ever
; shows the same window again, never creating a new one, so a
; handle already in here means "seen before", not "new". Cleared on
; EVENT_OBJECT_DESTROY, so a later, unrelated window that happens to
; reuse the same handle is not mistaken for one already seen.
global KnownWindows := Map()

; GW_OWNER
global GW_OWNER := 4

; WS_CHILD
global WS_CHILD := 0x40000000

; WINEVENT_OUTOFCONTEXT
WINEVENT_OUTOFCONTEXT := 0x0000

global WinEventCallback := CallbackCreate(
    WinEventProc,
    "Fast",
    7
)

; Create alone is not enough. An application that closes to the
; tray keeps its window, so opening it again shows the window
; that is already there and creates nothing. Worse, Windows
; reassigns such a window to whichever desktop is in front when
; it is shown, so a window the rule placed once does not stay
; placed. Show is what catches that.
;
; Create alone is also not enough the other way round: some apps'
; real top-level window (Windows Terminal, mintty) never fires a
; create event at all, only ever a show, even the first time. So
; both are let through, and KnownWindows is what actually tells a
; new window from a reopened one, not which event fired.
;
; The range takes in EVENT_OBJECT_DESTROY at 0x8001 too, which is
; used to forget a handle once its window is gone.
global WinEventHook := DllCall(
    "SetWinEventHook",
    "UInt", EVENT_OBJECT_CREATE,
    "UInt", EVENT_OBJECT_SHOW,
    "Ptr", 0,
    "Ptr", WinEventCallback,
    "UInt", 0,
    "UInt", 0,
    "UInt", WINEVENT_OUTOFCONTEXT,
    "Ptr"
)

OnExit Cleanup


WinEventProc(
    hWinEventHook,
    event,
    hwnd,
    idObject,
    idChild,
    idEventThread,
    dwmsEventTime
) {
    global KnownWindows

    ; CallbackCreate hands every parameter over as a 64 bit value,
    ; but event, idObject and idChild are 32 bit, so the upper half
    ; of each is whatever happened to be on the stack. Only the
    ; lower half carries any meaning, and without masking the
    ; checks below throw away the events they are meant to let
    ; through.
    event &= 0xFFFFFFFF
    idObject &= 0xFFFFFFFF
    idChild &= 0xFFFFFFFF

    if event != EVENT_OBJECT_CREATE && event != EVENT_OBJECT_SHOW && event != EVENT_OBJECT_DESTROY
        return

    ; Only interested in top-level windows
    if idObject != 0 || idChild != 0
        return

    ; Ignore invalid handles
    if !hwnd
        return

    if event = EVENT_OBJECT_DESTROY {
        if KnownWindows.Has(hwnd)
            KnownWindows.Delete(hwnd)
        return
    }

    HandleNewWindow(hwnd)
}


; ============================================================
; Window Processing
; ============================================================

HandleNewWindow(hwnd) {
    ; The event can occur before the process/window
    ; is fully ready, so defer processing slightly.
    SetTimer(
        (*) => ProcessNewWindow(hwnd),
        -100
    )
}


; Filters out everything that is not a real, top-level app window,
; then hands the survivors to whichever of centering and window
; rules applies.
ProcessNewWindow(hwnd) {
    global KnownWindows

    if !WinExist("ahk_id " hwnd)
        return

    ; Skip owned windows (dialogs, popups, pickers) - only move top-level app windows
    if DllCall("GetWindow", "Ptr", hwnd, "UInt", GW_OWNER, "Ptr")
        return

    ; Skip child windows. Chrome's "Chrome Legacy Window" is one,
    ; and it reports no owner, so the check above lets it past. It
    ; shows and hides several times per desktop switch, and it is
    ; not a window anyone means to place.
    try {
        if WinGetStyle("ahk_id " hwnd) & WS_CHILD
            return
    } catch {
        return
    }

    ; Whether this handle has been processed before, not which
    ; event fired, is what tells a new window from a reopened one:
    ; some apps' real window never fires a create event at all, only
    ; ever a show. Marked seen unconditionally, so toggling the
    ; setting on later never mistakes an already-known window for a
    ; new one.
    isNewWindow := !KnownWindows.Has(hwnd)
    KnownWindows[hwnd] := true

    if isNewWindow && Setting("AutoCenterWindows")
        CenterWindow(hwnd)

    ApplyRule(hwnd)
}


ApplyRule(hwnd) {
    global Rules

    try {
        processName := StrLower(
            WinGetProcessName("ahk_id " hwnd)
        )
    } catch {
        return
    }

    if !Rules.Has(processName)
        return

    target := Rules[processName] - 1

    ; Show fires on windows that never went anywhere, so check
    ; before moving. This keeps the common case down to one read.
    if DllCall(
        "VirtualDesktopAccessor\GetWindowDesktopNumber",
        "Ptr", hwnd,
        "Int"
    ) = target
        return

    ; The window is put where the rule says and nothing else is
    ; touched: no desktop switch, no focus change. Whatever
    ; Windows does in response is left alone.
    DllCall(
        "VirtualDesktopAccessor\MoveWindowToDesktopNumber",
        "Ptr", hwnd,
        "Int", target
    )
}


; ============================================================
; Cleanup
; ============================================================

Cleanup(*) {
    global WinEventHook, WinEventCallback

    if WinEventHook
        DllCall(
            "UnhookWinEvent",
            "Ptr", WinEventHook
        )

    if WinEventCallback
        CallbackFree(WinEventCallback)
}
