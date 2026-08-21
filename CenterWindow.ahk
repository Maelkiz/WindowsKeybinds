#Requires AutoHotkey v2

#c::
{
    hwnd := WinExist("A")

    WinGetPos(,, &width, &height, "ahk_id " hwnd)

    monitor := MonitorGetPrimary()
    MonitorGetWorkArea(monitor, &left, &top, &right, &bottom)

    x := left + ((right - left) - width) / 2
    y := top + ((bottom - top) - height) / 2

    WinMove(x, y,,, "ahk_id " hwnd)
}
