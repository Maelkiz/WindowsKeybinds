CenterActiveWindow() {
    hwnd := WinExist("A")

    if !hwnd
        return

    try
        WinGetPos(,, &width, &height, "ahk_id " hwnd)
    catch
        return

    monitor := MonitorGetPrimary()
    MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)

    x := left + ((right - left) - width) / 2
    y := top + ((bottom - top) - height) / 2

    try
        WinMove(x, y,,, "ahk_id " hwnd)
}
