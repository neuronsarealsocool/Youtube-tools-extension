$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$launcher = Join-Path $root 'Open YouTube Tools.cmd'
$desktop = [Environment]::GetFolderPath('DesktopDirectory')
$destination = Join-Path $desktop 'YouTube Tools.lnk'
if (-not (Test-Path -LiteralPath $launcher)) { throw 'The launcher is missing.' }
if (-not (Test-Path -LiteralPath $desktop)) { throw 'The Windows Desktop folder could not be found.' }
$shell = New-Object -ComObject WScript.Shell
if (Test-Path -LiteralPath $destination) {
    $existing = $shell.CreateShortcut($destination)
    if ($existing.TargetPath -ne $launcher) { throw 'A different YouTube Tools shortcut already exists on the desktop.' }
}
$shortcut = $shell.CreateShortcut($destination)
$shortcut.TargetPath = $launcher
$shortcut.WorkingDirectory = $root
$shortcut.Description = 'Start YouTube Tools and open YouTube'
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,14"
$shortcut.Save()
Write-Host "Desktop shortcut created: $destination"
