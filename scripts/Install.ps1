# Sets up WindowsKeybinds: makes the keybinds run on login, and
# creates the configuration file to edit them in.
#
# Safe to run again at any time. An existing config is left alone.

[CmdletBinding()]
param(
    # Start the keybinds straight away, rather than leaving them
    # until the next time you log in.
    [switch]$Start
)

. "$PSScriptRoot\Common.ps1"

$RepoDir = Split-Path $PSScriptRoot -Parent
$SrcDir = Join-Path $RepoDir "src"
$MasterScript = Join-Path $SrcDir "WindowsKeybinds.ahk"


# ------------------------------------------------------------
# Run on login
# ------------------------------------------------------------

$ShortcutPath = Get-ShortcutPath

try {
    $Shell = New-Object -ComObject WScript.Shell

    # Worth saying out loud when the clone has moved, so that
    # running this again does not look like it did nothing.
    $PreviousTarget = ""
    if (Test-Path $ShortcutPath) {
        $PreviousTarget = $Shell.CreateShortcut($ShortcutPath).TargetPath
    }

    New-Item -ItemType Directory -Path (Split-Path $ShortcutPath -Parent) -Force | Out-Null

    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $MasterScript
    $Shortcut.WorkingDirectory = $SrcDir
    $Shortcut.Save()

    Write-Host "Startup shortcut: $ShortcutPath"

    if ($PreviousTarget -and $PreviousTarget -ne $MasterScript) {
        Write-Host "  Repointed from:  $PreviousTarget"
    }
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

# Handed to Restart.ps1 rather than starting it here, so that there
# is only one place that knows how to stop and start the keybinds.
if ($Start) {
    & "$PSScriptRoot\Restart.ps1"
}
else {
    Write-Host "Run .\scripts\Restart.ps1 to start the keybinds now."
    Write-Host "  Or run this script with -Start to do both at once."
}
