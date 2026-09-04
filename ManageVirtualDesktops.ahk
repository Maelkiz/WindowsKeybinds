vda := DllCall(
    "LoadLibrary",
    "Str", A_ScriptDir "\VirtualDesktopAccessor.dll",
    "Ptr"
)

GoToDesktop(n) {
    DllCall(
        "VirtualDesktopAccessor\GoToDesktopNumber",
        "Int", n - 1
    )
}

MoveWindowToDesktop(n) {
    hwnd := WinGetID("A")

    DllCall(
        "VirtualDesktopAccessor\MoveWindowToDesktopNumber",
        "Ptr", hwnd,
        "Int", n - 1
    )
}
