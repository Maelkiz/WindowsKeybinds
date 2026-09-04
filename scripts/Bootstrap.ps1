# Sets up WindowsKeybinds: makes the keybinds run on login, and
# creates the configuration file to edit them in.
#
# Safe to run again at any time. An existing config is left alone.

. "$PSScriptRoot\Common.ps1"

$RepoDir = Split-Path $PSScriptRoot -Parent
$SrcDir = Join-Path $RepoDir "src"
$MasterScript = Join-Path $SrcDir "WindowsKeybinds.ahk"


# ------------------------------------------------------------
# Run on login
# ------------------------------------------------------------

$ShortcutPath = Get-ShortcutPath

try {
    New-Item -ItemType Directory -Path (Split-Path $ShortcutPath -Parent) -Force | Out-Null

    $Shell = New-Object -ComObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $MasterScript
    $Shortcut.WorkingDirectory = $SrcDir
    $Shortcut.Save()

    Write-Host "Startup shortcut: $ShortcutPath"
}
catch {
    Write-Warning "Could not create the startup shortcut: $($_.Exception.Message)"
}


# ------------------------------------------------------------
# Configuration file
# ------------------------------------------------------------

# Which paths get searched, and where a new config gets written, is
# decided by ConfigPaths.ahk. Ask the scripts through ConfigPath.ahk
# rather than writing that search order down a second time here.

if (-not (Find-AutoHotkey)) {
    Write-Warning "Could not find AutoHotkey v2, so no config file was created."
    Write-Host "  Install AutoHotkey v2, then run this script again."
    Write-Host "  The keybinds also create the config themselves when they first run."
    return
}

$ConfigPath = Get-ConfigPath -RepoDir $RepoDir -Mode ensure

if ($ConfigPath) {
    Write-Host "Configuration:    $ConfigPath"
}
else {
    Write-Warning "Could not create the configuration file."
}

Write-Host ""
Write-Host "Run .\scripts\Restart.ps1 to start the keybinds now."
