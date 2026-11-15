$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$launcher = Join-Path $root 'Open YouTube Tools.vbs'
$legacyLauncher = Join-Path $root 'Open YouTube Tools.cmd'
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$arguments = '"{0}"' -f $launcher
$desktop = [Environment]::GetFolderPath('DesktopDirectory')
$destination = Join-Path $desktop 'YouTube Tools.lnk'
if (-not (Test-Path -LiteralPath $launcher)) { throw 'The launcher is missing.' }
if (-not (Test-Path -LiteralPath $desktop)) { throw 'The Windows Desktop folder could not be found.' }
$shell = New-Object -ComObject WScript.Shell
if (Test-Path -LiteralPath $destination) {
    $existing = $shell.CreateShortcut($destination)
    $isLegacy = $existing.TargetPath -eq $legacyLauncher
    $isCurrent = $existing.TargetPath -eq $wscript -and $existing.Arguments -eq $arguments
    if (-not $isLegacy -and -not $isCurrent) { throw 'A different YouTube Tools shortcut already exists on the desktop.' }
}
$shortcut = $shell.CreateShortcut($destination)
$shortcut.TargetPath = $wscript
$shortcut.Arguments = $arguments
$shortcut.WorkingDirectory = $root
$shortcut.Description = 'Start YouTube Tools and open YouTube'
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,14"
$shortcut.Save()
Write-Host "Desktop shortcut created: $destination"
