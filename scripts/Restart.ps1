# Stops the keybinds running from the installed copy, then starts
# them again. Use this after editing one of the AutoHotkey scripts.
# Changes to the config file are picked up on their own.

. "$PSScriptRoot\Common.ps1"

$OwnDir = Split-Path $PSScriptRoot -Parent
$InstallDir = Resolve-InstallDir -FallbackDir $OwnDir

if ($InstallDir -ne $OwnDir) {
    Write-Host "Restarting the installed copy at: $InstallDir"
    Write-Host "  You ran this from:              $OwnDir"
    Write-Host "  Run .\scripts\Install.ps1 there first if you want that copy updated."
}

$MasterScript = Join-Path $InstallDir "src\WindowsKeybinds.ahk"

Stop-Keybinds -InstallDir $InstallDir | Out-Null

Start-Sleep -Milliseconds 300

Write-Host "Launching: $MasterScript"
Start-Process -FilePath $MasterScript -WorkingDirectory (Join-Path $InstallDir "src")
