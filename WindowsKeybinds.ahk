#Requires AutoHotkey v2
#SingleInstance Force

; Hotkeys come from the config file, so there may be none at all
; if it is broken. Stay running regardless, or the warning below
; would disappear along with the process.
Persistent

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
#Include WindowRules.ahk
#Include KeyNames.ahk
#Include Actions.ahk
#Include Config.ahk


; ============================================================
; Startup
; ============================================================

LoadConfig()
ReportConfigProblems()
