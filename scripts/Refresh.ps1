# Stops the running AutoHotkey instance for this repo, then relaunches the master script.
# Use this after editing a script to quickly reload it for testing.

$RepoDir = Split-Path $PSScriptRoot -Parent

Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe'" |
    Where-Object { $_.CommandLine -like "*$RepoDir*" } |
    ForEach-Object {
        Write-Host "Stopping: $($_.CommandLine)"
        Stop-Process -Id $_.ProcessId -Force
    }

Start-Sleep -Milliseconds 300

$MasterScript = Join-Path $RepoDir "src\WindowsKeybinds.ahk"
Write-Host "Launching: $MasterScript"
Start-Process -FilePath $MasterScript -WorkingDirectory (Join-Path $RepoDir "src")
