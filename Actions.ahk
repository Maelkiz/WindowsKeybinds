; ============================================================
; Actions available to the configuration file
;
; The names registered here are what gets written in config.ini.
; Keeping them separate from the function names means the
; configuration stays valid even if a function is renamed.
; ============================================================

global Actions := Map()

RegisterAction(name, fn, params := "") {
    global Actions

    Actions[StrLower(name)] := {
        name: name,
        fn: fn,
        params: params = "" ? [] : params
    }
}

; Bound to a key to stop Windows doing anything with it.
DoNothing(*) {
}

RegisterAction("CenterWindow",        CenterActiveWindow)
RegisterAction("CloseWindow",         CloseActiveWindow)
RegisterAction("LaunchBrowser",       LaunchBrowser)
RegisterAction("LaunchTerminal",      LaunchNewTerminal)
RegisterAction("ToggleMaximization",  ToggleMaximizeActiveWindow)
RegisterAction("ToggleDesktopIcons",  ToggleDesktopIcons)
RegisterAction("GoToDesktop",         GoToDesktop,         ["int"])
RegisterAction("MoveWindowToDesktop", MoveWindowToDesktop, ["int"])
RegisterAction("None",                DoNothing)


; Turns a configuration value such as "GoToDesktop 1" into the
; action to run and the arguments to hand it.
ResolveAction(value) {
    global Actions

    parts := []
    for part in StrSplit(Trim(value), " ") {
        if Trim(part) != ""
            parts.Push(Trim(part))
    }

    if !parts.Length
        throw ValueError("No action given")

    name := parts.RemoveAt(1)

    if !Actions.Has(StrLower(name))
        throw ValueError('Unknown action "' name '"')

    action := Actions[StrLower(name)]

    if parts.Length != action.params.Length
        throw ValueError(
            'Action "' action.name '" takes ' action.params.Length
            ' argument(s) but got ' parts.Length
        )

    for index, expected in action.params {
        if expected = "int" && !IsInteger(parts[index])
            throw ValueError(
                'Argument ' index ' of "' action.name '" should be a whole'
                ' number but was "' parts[index] '"'
            )
    }

    return { action: action, args: parts }
}


; Built in a function of its own so that every hotkey gets a
; separate closure. Sharing one would leave every binding
; running whichever action was registered last.
MakeActionHandler(action, args) {
    return (*) => action.fn.Call(args*)
}
