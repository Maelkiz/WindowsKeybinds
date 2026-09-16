# Removes WindowsKeybinds: stops the keybinds, stops them running
# on login, and removes the installed copy of the files.
#
# Your configuration is kept unless -RemoveConfig is given. A clone
# you are running -InPlace from is never touched. Safe to run more
# than once.

[CmdletBinding()]
param(
    # Delete the configuration file as well.
    [switch]$RemoveConfig,

    # Remove the startup shortcut even if it belongs elsewhere.
    [switch]$Force
)

. "$PSScriptRoot\Common.ps1"

$OwnDir = Split-Path $PSScriptRoot -Parent
$InstallDir = Resolve-InstallDir -FallbackDir $OwnDir
$MasterScript = Join-Path $InstallDir "src\WindowsKeybinds.ahk"


# ------------------------------------------------------------
# Stop the keybinds
# ------------------------------------------------------------

# Before anything else. A running instance writes the config back
# out from the template whenever it reloads, which would undo
# -RemoveConfig, and it would otherwise keep the keybinds live
# until the next reboot.
#
# Stopped from both the resolved install and the directory this was
# run from, so an in-place instance left running from an old clone
# does not survive a later, proper install being uninstalled.

$Stopped = (Stop-Keybinds -InstallDir $InstallDir)
if ($OwnDir -ne $InstallDir) {
    $Stopped += (Stop-Keybinds -InstallDir $OwnDir)
}
if ($Stopped -eq 0) {
    Write-Host "Keybinds:         not running"
}


# ------------------------------------------------------------
# Stop running on login
# ------------------------------------------------------------

$ShortcutPath = Get-ShortcutPath

if (-not (Test-Path $ShortcutPath)) {
    Write-Host "Startup shortcut: none found"
}
else {
    $Shell = New-Object -ComObject WScript.Shell
    $Target = $Shell.CreateShortcut($ShortcutPath).TargetPath

    # Another install may own this shortcut, and removing it would
    # break that installation rather than this one.
    if ($Target -and $Target -ne $MasterScript -and -not $Force) {
        Write-Warning "The startup shortcut belongs to another copy, so it was left alone:"
        Write-Host "    $Target"
        Write-Host "  Run with -Force to remove it anyway."
    }
    else {
        Remove-Item $ShortcutPath -Force
        Write-Host "Startup shortcut: removed"
    }
}


# ------------------------------------------------------------
# Configuration file
# ------------------------------------------------------------

# Asked for in find mode, so that uninstalling cannot end up
# creating the very file it is about to report on.

if (-not (Find-AutoHotkey)) {
    Write-Warning "Could not find AutoHotkey v2, so the configuration was not looked for."
    Write-Host "  It is usually at %USERPROFILE%\.config\WindowsKeybinds\config.ini"
}
else {
    $ConfigPath = Get-ConfigPath -InstallDir $InstallDir -Mode find

    if (-not $ConfigPath) {
        Write-Host "Configuration:    none found"
    }
    elseif (-not $RemoveConfig) {
        Write-Host "Configuration:    left in place"
        Write-Host "    $ConfigPath"
        Write-Host "  Run with -RemoveConfig to delete it."
    }
    else {
        Remove-Item $ConfigPath -Force
        Write-Host "Configuration:    removed"

        # Only when we are what emptied it. Other things may well
        # live under .config, so never remove it recursively.
        $ConfigDir = Split-Path $ConfigPath -Parent
        if ((Test-Path $ConfigDir) -and
            (@(Get-ChildItem $ConfigDir -Force).Count -eq 0)) {
            Remove-Item $ConfigDir -Force
            Write-Host "                  and its now empty folder"
        }
    }
}


# ------------------------------------------------------------
# Installed copy
# ------------------------------------------------------------

# Only ever removed when the marker file proves Install.ps1 put it
# there. An -InPlace install never gets one, since nothing was ever
# copied into the clone, so this naturally leaves a clone alone
# without having to ask separately whether this is one.
#
# When this is the installed copy's own Uninstall.ps1, this deletes
# the very file that is running. PowerShell has already read the
# whole script in by this point, so that is safe.

Write-Host ""

if (Test-OurInstall -InstallDir $InstallDir) {
    Remove-Item $InstallDir -Recurse -Force
    Write-Host "Installed copy:   removed"
    Write-Host "    $InstallDir"
}
else {
    Write-Host "Installed copy:   left in place, this looks like a clone rather than a copy"
    Write-Host "    $InstallDir"
    Write-Host "Delete it yourself whenever you like."
}
