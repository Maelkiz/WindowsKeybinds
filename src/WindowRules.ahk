; ============================================================
; Rules
; ============================================================

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

; OBJID_WINDOW
OBJID_WINDOW := 0

; GW_OWNER
global GW_OWNER := 4

; WINEVENT_OUTOFCONTEXT
WINEVENT_OUTOFCONTEXT := 0x0000

global WinEventCallback := CallbackCreate(
    WinEventProc,
    "Fast",
    7
)

global WinEventHook := DllCall(
    "SetWinEventHook",
    "UInt", EVENT_OBJECT_CREATE,
    "UInt", EVENT_OBJECT_CREATE,
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
    ; but idObject and idChild are 32 bit, so the upper half of each
    ; is whatever happened to be on the stack. Only the lower half
    ; carries any meaning, and without masking the check below
    ; throws away the window events it is meant to let through.
    idObject &= 0xFFFFFFFF
    idChild &= 0xFFFFFFFF

    ; Only interested in top-level windows
    if idObject != 0 || idChild != 0
        return

    ; Ignore invalid handles
    if !hwnd
        return

    HandleNewWindow(hwnd)
}


; ============================================================
; Window Processing
; ============================================================

HandleNewWindow(hwnd) {
    global Rules

    ; The event can occur before the process/window
    ; is fully ready, so defer processing slightly.
    SetTimer(
        (*) => ApplyRule(hwnd),
        -100
    )
}


ApplyRule(hwnd) {
    global Rules

    if !WinExist("ahk_id " hwnd)
        return

    ; Skip owned windows (dialogs, popups, pickers) - only move top-level app windows
    if DllCall("GetWindow", "Ptr", hwnd, "UInt", GW_OWNER, "Ptr")
        return

    try {
        processName := StrLower(
            WinGetProcessName("ahk_id " hwnd)
        )
    } catch {
        return
    }

    if !Rules.Has(processName)
        return

    desktop := Rules[processName]

    DllCall(
        "VirtualDesktopAccessor\MoveWindowToDesktopNumber",
        "Ptr", hwnd,
        "Int", desktop - 1
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
