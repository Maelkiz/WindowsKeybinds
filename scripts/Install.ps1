# Sets up WindowsKeybinds: copies the files to a per-user install
# location, makes the keybinds run on login from there, and creates
# the configuration file to edit them in.
#
# Safe to run again at any time. An existing config is left alone,
# and re-running updates an existing install rather than duplicating
# it.

[CmdletBinding()]
param(
    # Start the keybinds straight away, rather than leaving them
    # until the next time you log in.
    [switch]$Start,

    # Run the keybinds straight from this clone instead of copying
    # them anywhere. Editing src\ then only takes a Restart, at the
    # cost of the clone having to stay put and stay working, since it
    # is now what runs on login.
    [switch]$InPlace,

    # Install somewhere other than the default. Mainly for testing.
    [string]$InstallDir
)

. "$PSScriptRoot\Common.ps1"

if ($InPlace -and $InstallDir) {
    Write-Warning "-InPlace and -InstallDir contradict each other, so pick one."
    return
}

$SourceDir = Split-Path $PSScriptRoot -Parent

if ($InPlace) {
    $TargetDir = $SourceDir
}
elseif ($InstallDir) {
    $TargetDir = $InstallDir
}
else {
    $TargetDir = Get-InstallDir
}

# Full and case-normalised, so a trailing slash or different casing
# cannot defeat the "is this the same directory" check below.
$SourceFull = [IO.Path]::GetFullPath($SourceDir).TrimEnd('\')
$TargetFull = [IO.Path]::GetFullPath($TargetDir).TrimEnd('\')
$SameDir = $SourceFull.Equals($TargetFull, [StringComparison]::OrdinalIgnoreCase)

# Also catches the installed copy's own Install.ps1 being run: its
# source and its default target are the same directory. Copying a
# directory onto itself makes no sense, so this is refused rather
# than guessed at.
if ($SameDir -and -not $InPlace) {
    Write-Warning "This looks like the installed copy's own installer."
    Write-Host "  Installs are made from a clone. Run Install.ps1 from yours to update this copy,"
    Write-Host "  or run this one with -InPlace if you mean to run the keybinds from here instead."
    return
}

$WasRunning = $false


# ------------------------------------------------------------
# Copy the files
# ------------------------------------------------------------

if ($SameDir) {
    Write-Host "Install:          $TargetDir (running in place)"
}
else {
    # A non-empty directory that is not already one of our installs
    # is left alone, rather than overwriting files that might belong
    # to something else entirely.
    if ((Test-Path $TargetDir) -and
        (@(Get-ChildItem $TargetDir -Force -ErrorAction SilentlyContinue).Count -gt 0) -and
        -not (Test-OurInstall -InstallDir $TargetDir)) {
        Write-Warning "Refusing to install into a non-empty directory that isn't already a WindowsKeybinds install:"
        Write-Host "    $TargetDir"
        return
    }

    # The DLL is held open by a running instance (LoadLibrary), so it
    # has to stop before its file can be overwritten. The source
    # clone is stopped too: #SingleInstance Force keys on the
    # script's own path, so an instance launched from the clone is
    # not displaced just because the installed one starts, and the
    # two would otherwise fight over the same hotkeys.
    if ((Stop-Keybinds -InstallDir $TargetDir) -gt 0) { $WasRunning = $true }
    if ((Stop-Keybinds -InstallDir $SourceDir) -gt 0) { $WasRunning = $true }

    # Cleared first, so files removed from the repo do not linger in
    # the install. Only once the marker proves the directory is
    # already one of ours; a fresh target is simply created below.
    if (Test-OurInstall -InstallDir $TargetDir) {
        foreach ($sub in @("src", "defaults", "lib", "scripts")) {
            $dir = Join-Path $TargetDir $sub
            if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        }
    }

    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

    foreach ($sub in @("src", "defaults", "lib", "scripts")) {
        Copy-Item (Join-Path $SourceDir $sub) (Join-Path $TargetDir $sub) -Recurse -Force
    }

    # Not shipped files. config.ini is the user's own and belongs to
    # the source tree, not the install; Install.ps1 installs, so its
    # own copy could otherwise reinstall from itself.
    $InstalledConfig = Join-Path $TargetDir "src\config.ini"
    if (Test-Path $InstalledConfig) { Remove-Item $InstalledConfig -Force }
    Remove-Item (Join-Path $TargetDir "scripts\Install.ps1") -Force

    # The marker: what proves a directory is one of our installs, so
    # a later Install or Uninstall knows it is safe to touch. Best
    # effort, since a missing git or a source that is not a repo
    # should not stop the install itself.
    $CommitHash = ""
    try {
        $CommitHash = (git -C $SourceDir rev-parse --short HEAD 2>$null)
        if ($LASTEXITCODE -ne 0) { $CommitHash = "" }
    }
    catch {
        $CommitHash = ""
    }

    Set-Content -Path (Get-MarkerPath -InstallDir $TargetDir) -Encoding UTF8 -Value @(
        "[Install]"
        "Source = $SourceDir"
        "Commit = $CommitHash"
        "InstalledAt = $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    )

    Write-Host "Install:          $TargetDir"
}

$MasterScript = Join-Path $TargetDir "src\WindowsKeybinds.ahk"


# ------------------------------------------------------------
# Run on login
# ------------------------------------------------------------

$ShortcutPath = Get-ShortcutPath

try {
    $Shell = New-Object -ComObject WScript.Shell

    # Worth saying out loud when the install has moved, so that
    # running this again does not look like it did nothing.
    $PreviousTarget = ""
    if (Test-Path $ShortcutPath) {
        $PreviousTarget = $Shell.CreateShortcut($ShortcutPath).TargetPath
    }

    New-Item -ItemType Directory -Path (Split-Path $ShortcutPath -Parent) -Force | Out-Null

    $Shortcut = $Shell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $MasterScript
    $Shortcut.WorkingDirectory = Join-Path $TargetDir "src"
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

$NoAutoHotkey = $false

if (-not (Find-AutoHotkey)) {
    $NoAutoHotkey = $true
    Write-Warning "Could not find AutoHotkey v2, so no config file was created."
    Write-Host "  Install AutoHotkey v2, then run this script again."
    Write-Host "  The keybinds also create the config themselves when they first run."
}
else {
    $ConfigPath = Get-ConfigPath -InstallDir $TargetDir -Mode ensure

    if ($ConfigPath) {
        Write-Host "Configuration:    $ConfigPath"
    }
    else {
        Write-Warning "Could not create the configuration file."
    }
}

Write-Host ""

# Handed to the installed Restart.ps1 rather than starting it here,
# so that there is only one place that knows how to stop and start
# the keybinds, and so this always launches the copy that was just
# installed rather than whatever happened to be running before.
if ($NoAutoHotkey) {
    # Nothing to launch without AutoHotkey; the warning above already
    # said so, and nothing needed stopping either.
}
elseif ($Start -or $WasRunning) {
    & (Join-Path $TargetDir "scripts\Restart.ps1")
}
else {
    Write-Host "Run .\scripts\Restart.ps1 to start the keybinds now."
    Write-Host "  Or run this script with -Start to do both at once."
}
