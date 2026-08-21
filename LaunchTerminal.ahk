#Requires AutoHotkey v2

#Enter:: {
    existing := Map()

    for hwnd in WinGetList("ahk_exe WindowsTerminal.exe")
        existing[hwnd] := true

    Run "wt.exe -w new"

    deadline := A_TickCount + 3000
    newHwnd := 0

    while A_TickCount < deadline {
        for hwnd in WinGetList("ahk_exe WindowsTerminal.exe") {
            if !existing.Has(hwnd) {
                newHwnd := hwnd
                break
            }
        }

        if newHwnd
            break

        Sleep 50
    }

    if newHwnd {
        WinActivate "ahk_id " newHwnd
        WinWaitActive "ahk_id " newHwnd,, 1
    }
}