$RepoDir = $PSScriptRoot

$StartupDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"

New-Item -ItemType Directory -Path $StartupDir -Force | Out-Null

$Shell = New-Object -ComObject WScript.Shell

$AhkFile = Join-Path $RepoDir "WindowsKeybinds.ahk"
$ShortcutPath = Join-Path $StartupDir "WindowsKeybinds.lnk"

$Shortcut = $Shell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $AhkFile
$Shortcut.WorkingDirectory = $RepoDir
$Shortcut.Save()

Write-Host "Created: $ShortcutPath"
