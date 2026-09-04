; MONITOR_DEFAULTTONEAREST
global MONITOR_DEFAULTTONEAREST := 2

CenterActiveWindow() {
    hwnd := WinExist("A")

    if !hwnd
        return

    try
        WinGetPos(,, &width, &height, "ahk_id " hwnd)
    catch
        return

    if !GetWindowWorkArea(hwnd, &left, &top, &right, &bottom)
        return

    x := left + ((right - left) - width) / 2
    y := top + ((bottom - top) - height) / 2

    try
        WinMove(x, y,,, "ahk_id " hwnd)
}


; Work area of the monitor the window currently sits on,
; excluding the taskbar and other docked app bars.
GetWindowWorkArea(hwnd, &left, &top, &right, &bottom) {
    global MONITOR_DEFAULTTONEAREST

    monitor := DllCall(
        "MonitorFromWindow",
        "Ptr", hwnd,
        "UInt", MONITOR_DEFAULTTONEAREST,
        "Ptr"
    )

    if !monitor
        return false

    ; MONITORINFO: cbSize, rcMonitor, rcWork, dwFlags
    info := Buffer(40, 0)
    NumPut("UInt", 40, info, 0)

    if !DllCall("GetMonitorInfoW", "Ptr", monitor, "Ptr", info, "Int")
        return false

    ; rcWork starts at offset 20
    left   := NumGet(info, 20, "Int")
    top    := NumGet(info, 24, "Int")
    right  := NumGet(info, 28, "Int")
    bottom := NumGet(info, 32, "Int")

    return true
}
