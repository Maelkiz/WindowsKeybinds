#Requires AutoHotkey v2

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

; Win + Number → Switch to desktop

#1::GoToDesktop(1)
#2::GoToDesktop(2)
#3::GoToDesktop(3)
#4::GoToDesktop(4)
#5::GoToDesktop(5)
#6::GoToDesktop(6)
#7::GoToDesktop(7)
#8::GoToDesktop(8)
#9::GoToDesktop(9)
#0::GoToDesktop(10)

; Win + Shift + Number → Move active window to desktop

#+1::MoveWindowToDesktop(1)
#+2::MoveWindowToDesktop(2)
#+3::MoveWindowToDesktop(3)
#+4::MoveWindowToDesktop(4)
#+5::MoveWindowToDesktop(5)
#+6::MoveWindowToDesktop(6)
#+7::MoveWindowToDesktop(7)
#+8::MoveWindowToDesktop(8)
#+9::MoveWindowToDesktop(9)
#+0::MoveWindowToDesktop(10)