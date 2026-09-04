# Sets up WindowsKeybinds: makes the keybinds run on login, and
# creates the configuration file to edit them in.
#
# Safe to run again at any time. An existing config is left alone.

$RepoDir = Split-Path $PSScriptRoot -Parent
$SrcDir = Join-Path $RepoDir "src"
$MasterScript = Join-Path $SrcDir "WindowsKeybinds.ahk"


# ------------------------------------------------------------
# Run on login
# ------------------------------------------------------------

$StartupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = Join-Path $StartupDir "WindowsKeybinds.lnk"

try {
    New-Item -ItemType Directory -Path $StartupDir -Force | Out-Null

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
# decided by ConfigPaths.ahk. Ask the scripts through EnsureConfig.ahk
# rather than writing that search order down a second time here.

$Bases = @()
if ($env:ProgramFiles)        { $Bases += $env:ProgramFiles }
if (${env:ProgramFiles(x86)}) { $Bases += ${env:ProgramFiles(x86)} }
if ($env:LOCALAPPDATA)        { $Bases += (Join-Path $env:LOCALAPPDATA "Programs") }

$AhkExe = $null
foreach ($Base in $Bases) {
    foreach ($Name in @("AutoHotkey64.exe", "AutoHotkey32.exe")) {
        $Candidate = Join-Path $Base "AutoHotkey\v2\$Name"
        if (Test-Path $Candidate) {
            $AhkExe = $Candidate
            break
        }
    }
    if ($AhkExe) { break }
}

if (-not $AhkExe) {
    Write-Warning "Could not find AutoHotkey v2, so no config file was created."
    Write-Host "  Install AutoHotkey v2, then run this script again."
    Write-Host "  The keybinds also create the config themselves when they first run."
    return
}

# AutoHotkey cannot write to stdout, so it reports the path in a file.
$EnsureScript = Join-Path $SrcDir "EnsureConfig.ahk"
$PathFile = Join-Path $env:TEMP "WindowsKeybinds-config-path.txt"

if (Test-Path $PathFile) { Remove-Item $PathFile -Force }

Start-Process -FilePath $AhkExe `
    -ArgumentList "`"$EnsureScript`"", "`"$PathFile`"" `
    -Wait | Out-Null

$ConfigPath = ""
if (Test-Path $PathFile) {
    $ConfigPath = (Get-Content $PathFile -Raw).Trim()
    Remove-Item $PathFile -Force
}

if ($ConfigPath) {
    Write-Host "Configuration:    $ConfigPath"
}
else {
    Write-Warning "Could not create the configuration file."
}

Write-Host ""
Write-Host "Run .\scripts\Restart.ps1 to start the keybinds now."
