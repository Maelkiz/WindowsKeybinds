; ============================================================
; Reports where the configuration file is, writing the path into
; the file named by the first argument.
;
;   ConfigPath.ahk <outfile> ensure    create one if there is none
;   ConfigPath.ahk <outfile> find      never create anything
;
; The PowerShell scripts use this so that the search order for
; the config only ever lives in ConfigPaths.ahk.
;
; Exits 0 when a path was written, 1 when there was none to
; report, and 2 when called wrongly.
; ============================================================

#Requires AutoHotkey v2

#Include ConfigPaths.ahk

if A_Args.Length < 2
    ExitApp(2)

outFile := A_Args[1]
mode := StrLower(A_Args[2])

; Deliberately without a default. Guessing at the mode would mean
; guessing in favour of creating files, which is the wrong way
; round for a script that is also used while uninstalling.
if mode = "ensure"
    configPath := EnsureConfigExists()
else if mode = "find"
    configPath := FindConfigPath()
else
    ExitApp(2)

try
    FileDelete(outFile)

if configPath != ""
    FileAppend(configPath, outFile, "UTF-8-RAW")

ExitApp(configPath = "" ? 1 : 0)
