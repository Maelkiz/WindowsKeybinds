; ============================================================
; Configuration file loading
;
; Keybinds and window rules live in an ini file outside this
; repository, so that customising them does not mean editing
; tracked source files. ConfigPaths.ahk decides where it lives.
; ============================================================

global ConfigPath := ""
global ConfigProblems := []


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


; Works out what a configuration file asks for without changing
; anything, so that a new one can be checked before it is acted on.
ResolveConfig(path) {
    problems := []
    bindings := []
    rules := []

    bound := Map()

    for entry in ReadConfigSection(path, "Keybinds") {
        try
            hotkeyString := ToHotkeyString(entry.key)
        catch Error as problem {
            problems.Push("[Keybinds] " problem.Message)
            continue
        }

        if bound.Has(hotkeyString) {
            problems.Push(
                '[Keybinds] "' entry.key '" is bound twice'
                ' (already bound as "' bound[hotkeyString] '")'
            )
            continue
        }

        try
            resolved := ResolveAction(entry.value)
        catch Error as problem {
            problems.Push("[Keybinds] " entry.key ": " problem.Message)
            continue
        }

        bound[hotkeyString] := entry.key

        bindings.Push({
            key: entry.key,
            hotkey: hotkeyString,
            action: resolved.action,
            args: resolved.args
        })
    }

    for entry in ReadConfigSection(path, "WindowRules") {
        if !IsInteger(entry.value) {
            problems.Push(
                '[WindowRules] Desktop for "' entry.key '" should be a whole'
                ' number but was "' entry.value '"'
            )
            continue
        }

        rules.Push({
            process: entry.key,
            desktop: Integer(entry.value)
        })
    }

    return { bindings: bindings, rules: rules, problems: problems }
}


LoadConfig() {
    global ConfigPath, ConfigProblems

    ConfigProblems := []

    path := EnsureConfigExists()

    if path = "" {
        ConfigProblems.Push("Found no configuration file and could not create one.")
        return false
    }

    ConfigPath := path

    resolved := ResolveConfig(path)
    ConfigProblems := resolved.problems

    for binding in resolved.bindings {
        ; AutoHotkey decides what counts as a real key name, so let
        ; it reject anything the alias table happily passed through.
        try
            Hotkey(
                binding.hotkey,
                MakeActionHandler(binding.action, binding.args)
            )
        catch Error as problem
            ConfigProblems.Push(
                '[Keybinds] Could not bind "' binding.key '": ' problem.Message
            )
    }

    for rule in resolved.rules
        AddRule(rule.process, rule.desktop)

    return true
}


; A tray notification rather than a MsgBox, so that a typo in the
; config does not block the rest of the keybinds from working.
ReportConfigProblems(context := "") {
    global ConfigProblems

    if !ConfigProblems.Length
        return

    shown := Min(ConfigProblems.Length, 5)

    message := ""
    loop shown
        message .= "- " ConfigProblems[A_Index] "`n"

    if ConfigProblems.Length > shown
        message .= "- and " (ConfigProblems.Length - shown) " more`n"

    title := "WindowsKeybinds: " ConfigProblems.Length " configuration problem(s)"

    if context != ""
        title .= " - " context

    TrayTip(message, title)
}
