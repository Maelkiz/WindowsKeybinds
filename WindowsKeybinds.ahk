#Requires AutoHotkey v2
#SingleInstance Force

; ============================================================
; Includes
; ============================================================

#Include CenterWindow.ahk
#Include CloseWindow.ahk
#Include LaunchBrowser.ahk
#Include LaunchTerminal.ahk
#Include ManageVirtualDesktops.ahk
#Include ToggleDekstopIcons.ahk
#Include ToggleMaximization.ahk
#Include UnbindWindowsKeybinds.ahk
#Include WindowRules.ahk


; ============================================================
; Window Rules Configuration
; ============================================================

AddRule("chrome.exe", 2)
AddRule("Code.exe",   3)


; ============================================================
; Keybindings
; ============================================================

#c::CenterActiveWindow()
#q::CloseActiveWindow()
#b::LaunchBrowser()
#Enter::LaunchNewTerminal()
#f::ToggleMaximizeActiveWindow()
#F12::ToggleDesktopIcons()
F1::DisableF1Help()

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
