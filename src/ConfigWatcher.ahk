; ============================================================
; Reloading the configuration when the file changes
;
; The file is polled rather than hooked. Editors save in different
; ways, some writing a temporary file and renaming it over the
; original, so a change is only acted on once the contents have
; stopped moving. That way a half written file is never mistaken
; for the new configuration.
; ============================================================

global WatchIntervalMs := 1000

; What the file said when it was last looked at, which is not
; always what is running: a config that fails to validate is
; recorded here too, so that it is only complained about once.
global LastSeenConfig := ""

; A change waiting to be confirmed by the next look at the file.
global PendingConfig := ""


StartConfigWatcher() {
    global ConfigPath, LastSeenConfig, WatchIntervalMs

    if ConfigPath = ""
        return

    text := ""
    if ReadConfigText(ConfigPath, &text)
        LastSeenConfig := text

    SetTimer(CheckConfigForChanges, WatchIntervalMs)
}


CheckConfigForChanges() {
    global ConfigPath, ConfigProblems, LastSeenConfig, PendingConfig

    current := ""

    ; Missing, or locked by whatever is writing it. Keep running
    ; what is already loaded and look again next time.
    if !ReadConfigText(ConfigPath, &current) {
        PendingConfig := ""
        return
    }

    if current == LastSeenConfig {
        PendingConfig := ""
        return
    }

    ; Only act once the same contents have been seen twice, so that
    ; a file still being written gets left alone until it settles.
    if current !== PendingConfig {
        PendingConfig := current
        return
    }

    LastSeenConfig := current
    PendingConfig := ""

    problems := ResolveConfig(ConfigPath).problems

    ; Keep the keybinds that are working rather than reloading into
    ; a config that is known to be broken.
    if problems.Length {
        ConfigProblems := problems
        ReportConfigProblems("not reloaded")
        return
    }

    Reload()
}
