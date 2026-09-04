; ============================================================
; Creates the configuration file if there is not one already, and
; writes its path to the file named by the first argument.
;
; Bootstrap.ps1 uses this so that the search order for the config
; only ever lives in ConfigPaths.ahk.
; ============================================================

#Requires AutoHotkey v2

#Include ConfigPaths.ahk

configPath := EnsureConfigExists()

if A_Args.Length {
    try
        FileDelete(A_Args[1])

    FileAppend(configPath, A_Args[1], "UTF-8-RAW")
}

ExitApp(configPath = "" ? 1 : 0)
