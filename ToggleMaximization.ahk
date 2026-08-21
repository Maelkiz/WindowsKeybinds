#Requires AutoHotkey v2

#f::
{
    hwnd := WinExist("A")

    if WinGetMinMax("ahk_id " hwnd) = 1
        WinRestore("ahk_id " hwnd)
    else
        WinMaximize("ahk_id " hwnd)
}
