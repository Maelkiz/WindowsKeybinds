#Requires AutoHotkey v2

GetDesktopListView() {
    progman := DllCall("FindWindowW", "WStr", "Progman", "Ptr", 0, "Ptr")
    if progman {
        shellView := DllCall("FindWindowExW", "Ptr", progman, "Ptr", 0, "WStr", "SHELLDLL_DefView", "Ptr", 0, "Ptr")
    }
    if !shellView {
        worker := 0
        loop {
            worker := DllCall("FindWindowExW", "Ptr", 0, "Ptr", worker, "WStr", "WorkerW", "Ptr", 0, "Ptr")
            if !worker
                break
            shellView := DllCall("FindWindowExW", "Ptr", worker, "Ptr", 0, "WStr", "SHELLDLL_DefView", "Ptr", 0, "Ptr")
            if shellView
                break
        }
    }
    if !shellView
        return 0

    return DllCall("FindWindowExW", "Ptr", shellView, "Ptr", 0, "WStr", "SysListView32", "Ptr", 0, "Ptr")
}

ToggleDesktopIcons() {
    lv := GetDesktopListView()
    if !lv {
        MsgBox("Could not locate desktop icons window.")
        return
    }

    visible := DllCall("IsWindowVisible", "Ptr", lv, "Int")
    DllCall("ShowWindow", "Ptr", lv, "Int", visible ? 0 : 5)
}

; Hotkey: Win + F12
#F12::ToggleDesktopIcons()
