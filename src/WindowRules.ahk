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

; EVENT_OBJECT_SHOW
global EVENT_OBJECT_SHOW := 0x8002

; OBJID_WINDOW
OBJID_WINDOW := 0

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
; The range takes in EVENT_OBJECT_DESTROY at 0x8001 as well,
; which WinEventProc drops.
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
    global Rules

    ; CallbackCreate hands every parameter over as a 64 bit value,
    ; but event, idObject and idChild are 32 bit, so the upper half
    ; of each is whatever happened to be on the stack. Only the
    ; lower half carries any meaning, and without masking the
    ; checks below throw away the events they are meant to let
    ; through.
    event &= 0xFFFFFFFF
    idObject &= 0xFFFFFFFF
    idChild &= 0xFFFFFFFF

    ; The hook covers destroy as well, which says nothing about
    ; where a window should live.
    if event != EVENT_OBJECT_CREATE && event != EVENT_OBJECT_SHOW
        return

    ; Only interested in top-level windows
    if idObject != 0 || idChild != 0
        return

    ; Ignore invalid handles
    if !hwnd
        return

    HandleNewWindow(hwnd, event)
}


; ============================================================
; Window Processing
; ============================================================

HandleNewWindow(hwnd, event) {
    ; The event can occur before the process/window
    ; is fully ready, so defer processing slightly.
    SetTimer(
        (*) => ProcessNewWindow(hwnd, event),
        -100
    )
}


; Filters out everything that is not a real, top-level app window,
; then hands the survivors to whichever of centering and window
; rules applies.
ProcessNewWindow(hwnd, event) {
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

    ; Centering only happens on an actual creation. A show can also
    ; mean an app un-hiding a window it kept open in the tray, and
    ; re-centering that would undo wherever the user had since
    ; moved it.
    if event = EVENT_OBJECT_CREATE && Setting("AutoCenterWindows")
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
