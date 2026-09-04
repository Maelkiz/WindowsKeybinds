# Helpers shared by the scripts in this folder.
#
# Dot-source it rather than running it:
#     . "$PSScriptRoot\Common.ps1"


# Where the shortcut that makes the keybinds run on login goes.
function Get-ShortcutPath {
    Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\WindowsKeybinds.lnk"
}


function Find-AutoHotkey {
    $bases = @()
    if ($env:ProgramFiles)        { $bases += $env:ProgramFiles }
    if (${env:ProgramFiles(x86)}) { $bases += ${env:ProgramFiles(x86)} }
    if ($env:LOCALAPPDATA)        { $bases += (Join-Path $env:LOCALAPPDATA "Programs") }

    foreach ($base in $bases) {
        foreach ($name in @("AutoHotkey64.exe", "AutoHotkey32.exe")) {
            $candidate = Join-Path $base "AutoHotkey\v2\$name"
            if (Test-Path $candidate) { return $candidate }
        }
    }

    return $null
}


# Asks the AutoHotkey side where the configuration file is, so that
# the search order only ever lives in src\ConfigPaths.ahk.
#
# Mode 'ensure' creates one when there is none, 'find' never does.
# Returns $null when there is no config, or when AutoHotkey itself
# cannot be found to ask.
function Get-ConfigPath {
    param(
        [Parameter(Mandatory = $true)][string]$RepoDir,
        [Parameter(Mandatory = $true)][ValidateSet("ensure", "find")][string]$Mode
    )

    $ahk = Find-AutoHotkey
    if (-not $ahk) { return $null }

    $helper = Join-Path $RepoDir "src\ConfigPath.ahk"
    $pathFile = Join-Path $env:TEMP "WindowsKeybinds-config-path.txt"

    if (Test-Path $pathFile) { Remove-Item $pathFile -Force }

    # AutoHotkey cannot write to stdout, so it reports the path in a file.
    Start-Process -FilePath $ahk `
        -ArgumentList "`"$helper`"", "`"$pathFile`"", $Mode `
        -Wait | Out-Null

    $configPath = ""
    if (Test-Path $pathFile) {
        $configPath = (Get-Content $pathFile -Raw).Trim()
        Remove-Item $pathFile -Force
    }

    if ($configPath) { return $configPath }

    return $null
}


# Stops the keybinds running from a given clone, and reports how
# many were stopped.
function Stop-Keybinds {
    param([Parameter(Mandatory = $true)][string]$RepoDir)

    # Matched with Contains rather than -like, so that a bracket in
    # the path cannot be read as a wildcard.
    $running = @(
        Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey32.exe'" |
            Where-Object { $_.CommandLine -and $_.CommandLine.Contains($RepoDir) }
    )

    foreach ($process in $running) {
        Write-Host "Stopping: $($process.CommandLine)"
        try {
            Stop-Process -Id $process.ProcessId -Force
        }
        catch {
            Write-Warning "Could not stop process $($process.ProcessId): $($_.Exception.Message)"
        }
    }

    return $running.Count
}
