; ============================================================
; Configuration file loading
;
; Keybinds and window rules live in an ini file outside this
; repository, so that customising them does not mean editing
; tracked source files. ConfigPaths.ahk decides where it lives.
; ============================================================

global ConfigPath := ""
global ConfigProblems := []


; Reports failure separately from the contents, so that an empty
; file and an unreadable one cannot be confused for one another.
ReadConfigText(path, &text) {
    try
        text := FileRead(path, "UTF-8")
    catch
        return false

    return true
}


; The whole file, parsed into { key, value } arrays by section and
; kept in file order.
;
; Parsed here rather than through the Windows ini functions, which
; do not recognise a UTF-8 byte order mark. A config saved that way
; would look completely empty to them, silently leaving no keybinds
; at all rather than reporting anything wrong.
ReadConfigSections(path) {
    sections := Map()
    sections.CaseSense := "Off"

    text := ""
    if !ReadConfigText(path, &text)
        return sections

    section := ""

    for line in StrSplit(text, "`n", "`r`t ") {
        if line = "" || SubStr(line, 1, 1) = ";"
            continue

        if SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]" {
            section := Trim(SubStr(line, 2, StrLen(line) - 2))

            if !sections.Has(section)
                sections[section] := []

            continue
        }

        ; Anything before the first section header has no home.
        if section = ""
            continue

        separator := InStr(line, "=")
        if !separator
            continue

        sections[section].Push({
            key: Trim(SubStr(line, 1, separator - 1)),
            value: Trim(SubStr(line, separator + 1))
        })
    }

    return sections
}


SectionEntries(sections, name) {
    return sections.Has(name) ? sections[name] : []
}


; Works out what a configuration file asks for without changing
; anything, so that a new one can be checked before it is acted on.
ResolveConfig(path) {
    sections := ReadConfigSections(path)

    problems := []
    bindings := []
    rules := []

    bound := Map()

    for entry in SectionEntries(sections, "Keybinds") {
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

    for entry in SectionEntries(sections, "WindowRules") {
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
