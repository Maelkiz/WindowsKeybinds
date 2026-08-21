$RepoDir = $PSScriptRoot

$StartupDir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"

New-Item -ItemType Directory -Path $StartupDir -Force | Out-Null

$Shell = New-Object -ComObject WScript.Shell

Get-ChildItem -Path $RepoDir -Filter "*.ahk" -File | ForEach-Object {
    $AhkFile = $_
    $ShortcutPath = Join-Path $StartupDir "$($AhkFile.BaseName).lnk"

    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $AhkFile.FullName
    $Shortcut.WorkingDirectory = $RepoDir
    $Shortcut.Save()

    Write-Host "Created: $ShortcutPath"
}