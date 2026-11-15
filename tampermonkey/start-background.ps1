$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $root '.local\dev'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$log = Join-Path $logDirectory 'startup.log'
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$launcher = Join-Path $PSScriptRoot 'start-local.ps1'
while ($true) {
    # Run in a child process so even a terminating error or exit cannot stop the monitor.
    & $powerShell -NoProfile -ExecutionPolicy Bypass -File $launcher *> $log
    Add-Content -LiteralPath $log -Value 'Service stopped; retrying in 10 seconds.'
    Start-Sleep -Seconds 10
}
