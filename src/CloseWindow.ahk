CloseActiveWindow() {
    if !WinExist("A")
        return

    Send "!{F4}"
}
