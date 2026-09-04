; ============================================================
; Human readable key names -> AutoHotkey hotkey strings
;
;   Super+C          ->  #c
;   Super+Shift+1    ->  #+1
;   Ctrl+Alt+Delete  ->  ^!Delete
; ============================================================

global ModifierSymbols := Map(
    "super",   "#",
    "win",     "#",
    "meta",    "#",
    "cmd",     "#",
    "ctrl",    "^",
    "control", "^",
    "alt",     "!",
    "opt",     "!",
    "option",  "!",
    "shift",   "+"
)

; Modifiers are always emitted in this order, so that
; Super+Shift+1 and Shift+Super+1 produce the same hotkey
; string and can be recognised as the same binding.
global ModifierOrder := ["#", "^", "!", "+"]

; Keys that either cannot be written in an ini file (= and ;
; in particular) or that are simply easier to read spelled out.
; These name physical keys, so Plus and Equals are the same key.
global BaseKeyAliases := Map(
    "plus",         "=",
    "equals",       "=",
    "minus",        "-",
    "hyphen",       "-",
    "dash",         "-",
    "comma",        ",",
    "period",       ".",
    "dot",          ".",
    "semicolon",    ";",
    "colon",        ";",
    "quote",        "'",
    "apostrophe",   "'",
    "slash",        "/",
    "backslash",    "\",
    "leftbracket",  "[",
    "rightbracket", "]",
    "backtick",     "``",
    "grave",        "``"
)


ToHotkeyString(name) {
    global ModifierSymbols, ModifierOrder, BaseKeyAliases

    name := Trim(name)

    if name = ""
        throw ValueError("No key given")

    parts := StrSplit(name, "+")

    ; An empty part means the name contained a bare +, such as
    ; "Super++". Plus is spelled out precisely to avoid this.
    for part in parts {
        if Trim(part) = ""
            throw ValueError('Could not read key "' name '", write Plus instead of a bare +')
    }

    base := Trim(parts.Pop())

    symbols := Map()
    for part in parts {
        modifier := StrLower(Trim(part))

        if !ModifierSymbols.Has(modifier)
            throw ValueError('Unknown modifier "' Trim(part) '" in "' name '"')

        symbols[ModifierSymbols[modifier]] := true
    }

    prefix := ""
    for symbol in ModifierOrder {
        if symbols.Has(symbol)
            prefix .= symbol
    }

    if BaseKeyAliases.Has(StrLower(base))
        base := BaseKeyAliases[StrLower(base)]
    else if StrLen(base) = 1
        ; AutoHotkey reads #c and #C as the same hotkey, so the
        ; base key stays lowercase and Shift is only ever a prefix.
        base := StrLower(base)

    return prefix base
}
