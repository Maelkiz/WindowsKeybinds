; ============================================================
; Where the configuration file lives
;
; Kept separate from the rest of the configuration handling so
; that Bootstrap.ps1 can ask for the path through EnsureConfig.ahk
; without the search order being written down in two places.
; ============================================================

; Searched in order, the first one that exists wins.
FindConfigPath() {
    candidates := []

    override := EnvGet("WINDOWSKEYBINDS_CONFIG")
    if override != ""
        candidates.Push(override)

    home := EnvGet("USERPROFILE")
    if home != ""
        candidates.Push(home "\.config\WindowsKeybinds\config.ini")

    appData := EnvGet("APPDATA")
    if appData != ""
        candidates.Push(appData "\WindowsKeybinds\config.ini")

    candidates.Push(A_ScriptDir "\config.ini")

    for candidate in candidates {
        if FileExist(candidate)
            return candidate
    }

    return ""
}


; Bootstrap.ps1 normally does this, but doing it here as well means
; the keybinds still work when the script is started some other way.
CreateDefaultConfig() {
    template := A_ScriptDir "\config.default.ini"
    home := EnvGet("USERPROFILE")

    if !FileExist(template) || home = ""
        return ""

    target := home "\.config\WindowsKeybinds\config.ini"

    try {
        DirCreate(home "\.config\WindowsKeybinds")
        FileCopy(template, target)
    } catch
        return ""

    return target
}


; The path to the configuration file, creating it from the template
; if there is not one already. Empty if that was not possible.
EnsureConfigExists() {
    path := FindConfigPath()

    if path != ""
        return path

    return CreateDefaultConfig()
}
