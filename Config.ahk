; ============================================================
; Configuration file loading
;
; Keybinds and window rules live in an ini file outside this
; repository, so that customising them does not mean editing
; tracked source files.
; ============================================================

global ConfigPath := ""
global ConfigProblems := []


; Searched in order, first one that exists wins.
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


; Without this a fresh clone would start up and do nothing at all.
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


; Returns the section as an array of { key, value }, in file order.
ReadConfigSection(path, section) {
    entries := []

    try
        raw := IniRead(path, section)
    catch
        return entries

    for line in StrSplit(raw, "`n", "`r") {
        line := Trim(line)

        if line = "" || SubStr(line, 1, 1) = ";"
            continue

        separator := InStr(line, "=")
        if !separator
            continue

        entries.Push({
            key: Trim(SubStr(line, 1, separator - 1)),
            value: Trim(SubStr(line, separator + 1))
        })
    }

    return entries
}


ApplyKeybinds(entries) {
    global ConfigProblems

    bound := Map()

    for entry in entries {
        try
            hotkeyString := ToHotkeyString(entry.key)
        catch Error as problem {
            ConfigProblems.Push("[Keybinds] " problem.Message)
            continue
        }

        if bound.Has(hotkeyString) {
            ConfigProblems.Push(
                '[Keybinds] "' entry.key '" is bound twice'
                ' (already bound as "' bound[hotkeyString] '")'
            )
            continue
        }

        try
            resolved := ResolveAction(entry.value)
        catch Error as problem {
            ConfigProblems.Push("[Keybinds] " entry.key ": " problem.Message)
            continue
        }

        ; AutoHotkey decides what counts as a real key name, so let
        ; it reject anything the alias table happily passed through.
        try
            Hotkey(
                hotkeyString,
                MakeActionHandler(resolved.action, resolved.args)
            )
        catch Error as problem {
            ConfigProblems.Push(
                '[Keybinds] Could not bind "' entry.key '": ' problem.Message
            )
            continue
        }

        bound[hotkeyString] := entry.key
    }
}


ApplyWindowRules(entries) {
    global ConfigProblems

    for entry in entries {
        if !IsInteger(entry.value) {
            ConfigProblems.Push(
                '[WindowRules] Desktop for "' entry.key '" should be a whole'
                ' number but was "' entry.value '"'
            )
            continue
        }

        AddRule(entry.key, Integer(entry.value))
    }
}


LoadConfig() {
    global ConfigPath, ConfigProblems

    ConfigProblems := []

    path := FindConfigPath()

    if path = ""
        path := CreateDefaultConfig()

    if path = "" {
        ConfigProblems.Push("Found no configuration file and could not create one.")
        return false
    }

    ConfigPath := path

    ApplyKeybinds(ReadConfigSection(path, "Keybinds"))
    ApplyWindowRules(ReadConfigSection(path, "WindowRules"))

    return true
}


; A tray notification rather than a MsgBox, so that a typo in the
; config does not block the rest of the keybinds from working.
ReportConfigProblems() {
    global ConfigProblems

    if !ConfigProblems.Length
        return

    shown := Min(ConfigProblems.Length, 5)

    message := ""
    loop shown
        message .= "- " ConfigProblems[A_Index] "`n"

    if ConfigProblems.Length > shown
        message .= "- and " (ConfigProblems.Length - shown) " more`n"

    TrayTip(
        message,
        "WindowsKeybinds: " ConfigProblems.Length " configuration problem(s)"
    )
}
