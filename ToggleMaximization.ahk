ToggleMaximizeActiveWindow() {
    hwnd := WinExist("A")

    if !hwnd
        return

    try {
        if WinGetMinMax("ahk_id " hwnd) = 1
            WinRestore("ahk_id " hwnd)
        else
            WinMaximize("ahk_id " hwnd)
    }
}
