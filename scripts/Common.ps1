# Helpers shared by the scripts in this folder.
#
# Dot-source it rather than running it:
#     . "$PSScriptRoot\Common.ps1"


# Name of the scheduled task that makes the keybinds run on login.
#
# A logon-triggered scheduled task starts as soon as the user logs
# in. A shortcut in the Startup folder does not: Explorer
# deliberately staggers Startup-folder apps for a while after logon
# to keep the desktop responsive, which is what used to make the
# keybinds take up to a minute to come alive.
function Get-TaskName {
    "WindowsKeybinds"
}


# Where older versions of this project put a Startup-folder
# shortcut, before it switched to a scheduled task. Only kept around
# so Install and Uninstall can clean up a leftover one.
function Get-LegacyShortcutPath {
    Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\WindowsKeybinds.lnk"
}


# Where Install.ps1 copies the files to by default, alongside other
# per-user installs such as AutoHotkey itself or VS Code.
function Get-InstallDir {
    Join-Path $env:LOCALAPPDATA "Programs\WindowsKeybinds"
}


# The file that marks a directory as one this project put there
# itself, rather than something else that happens to live at the
# default install path. Only a directory with this file gets its
# contents replaced or removed.
function Get-MarkerPath {
    param([Parameter(Mandatory = $true)][string]$InstallDir)
    Join-Path $InstallDir "install-info.ini"
}


function Test-OurInstall {
    param([Parameter(Mandatory = $true)][string]$InstallDir)
    Test-Path (Get-MarkerPath -InstallDir $InstallDir)
}


# Works out which directory actually owns the running keybinds, by
# following the logon scheduled task rather than assuming the caller
# is sitting in it. Restart and Uninstall use this so that running
# them from a clone acts on the real installation, not on the clone.
#
# Falls back to the default install directory if that exists, then
# to $FallbackDir (normally the caller's own parent directory), so
# there is still something sensible to act on when there is no task
# yet.
function Resolve-InstallDir {
    param([Parameter(Mandatory = $true)][string]$FallbackDir)

    $Task = Get-ScheduledTask -TaskName (Get-TaskName) -ErrorAction SilentlyContinue
    if ($Task) {
        try {
            # The action's working directory is "...\src"; the
            # install directory is one level up from that.
            $SrcDir = $Task.Actions[0].WorkingDirectory
            if ($SrcDir) {
                $Candidate = Split-Path $SrcDir -Parent
                if ($Candidate -and (Test-Path $Candidate)) {
                    return $Candidate
                }
            }
        }
        catch {
            # Fall through to the candidates below.
        }
    }

    $DefaultDir = Get-InstallDir
    if (Test-Path $DefaultDir) { return $DefaultDir }

    return $FallbackDir
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
        [Parameter(Mandatory = $true)][string]$InstallDir,
        [Parameter(Mandatory = $true)][ValidateSet("ensure", "find")][string]$Mode
    )

    $ahk = Find-AutoHotkey
    if (-not $ahk) { return $null }

    $helper = Join-Path $InstallDir "src\ConfigPath.ahk"
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


# Stops the keybinds running from a given directory (a clone or an
# install), and reports how many were stopped.
function Stop-Keybinds {
    param([Parameter(Mandatory = $true)][string]$InstallDir)

    # Matched with Contains rather than -like, so that a bracket in
    # the path cannot be read as a wildcard.
    $running = @(
        Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkey64.exe' OR Name = 'AutoHotkey32.exe'" |
            Where-Object { $_.CommandLine -and $_.CommandLine.Contains($InstallDir) }
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
