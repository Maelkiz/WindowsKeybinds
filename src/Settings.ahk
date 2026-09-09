; ============================================================
; Settings
;
; Named values the config file can set, kept apart from the
; keybinds and the window rules. Every setting listed here has a
; default, and anything not listed gets reported rather than
; ignored, so that a misspelled name cannot quietly do nothing.
; ============================================================

global SettingDefaults := Map()
SettingDefaults.CaseSense := "Off"

SettingDefaults["FollowManualMoves"] := true
SettingDefaults["FollowRuleMoves"] := true

global SettingValues := Map()
SettingValues.CaseSense := "Off"


; What the config file asked for, or the default if it said nothing.
Setting(name) {
    global SettingDefaults, SettingValues

    if SettingValues.Has(name)
        return SettingValues[name]

    if SettingDefaults.Has(name)
        return SettingDefaults[name]

    return false
}


ApplySettings(settings) {
    global SettingValues

    SettingValues := settings
}


; Reads the spellings people are likely to write, and refuses the
; rest so that a typo is reported instead of taken as false.
ParseBoolean(value, &result) {
    switch StrLower(Trim(value)) {
        case "true", "1":
            result := true
            return true

        case "false", "0":
            result := false
            return true
    }

    return false
}
