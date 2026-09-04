# Stops the keybinds running from this repo, then starts them again.
# Use this after editing one of the AutoHotkey scripts. Changes to
# the config file are picked up on their own.

. "$PSScriptRoot\Common.ps1"

$RepoDir = Split-Path $PSScriptRoot -Parent
$MasterScript = Join-Path $RepoDir "src\WindowsKeybinds.ahk"

Stop-Keybinds -RepoDir $RepoDir | Out-Null

Start-Sleep -Milliseconds 300

Write-Host "Launching: $MasterScript"
Start-Process -FilePath $MasterScript -WorkingDirectory (Join-Path $RepoDir "src")
