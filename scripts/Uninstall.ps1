# Removes WindowsKeybinds: stops the keybinds and stops them
# running on login.
#
# Your configuration is kept unless -RemoveConfig is given, and the
# clone itself is never touched. Safe to run more than once.

[CmdletBinding()]
param(
    # Delete the configuration file as well.
    [switch]$RemoveConfig,

    # Remove the startup shortcut even if it belongs elsewhere.
    [switch]$Force
)

. "$PSScriptRoot\Common.ps1"

$RepoDir = Split-Path $PSScriptRoot -Parent
$SrcDir = Join-Path $RepoDir "src"
$MasterScript = Join-Path $SrcDir "WindowsKeybinds.ahk"


# ------------------------------------------------------------
# Stop the keybinds
# ------------------------------------------------------------

# Before anything else. A running instance writes the config back
# out from the template whenever it reloads, which would undo
# -RemoveConfig, and it would otherwise keep the keybinds live
# until the next reboot.

if ((Stop-Keybinds -RepoDir $RepoDir) -eq 0) {
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

    # Another clone may own this shortcut, and removing it would
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
    $ConfigPath = Get-ConfigPath -RepoDir $RepoDir -Mode find

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

Write-Host ""
Write-Host "The clone itself was left alone, delete it whenever you like."
