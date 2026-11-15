$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$logDirectory = Join-Path $root '.local\dev'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$log = Join-Path $logDirectory 'startup.log'
$errorLog = Join-Path $logDirectory 'startup-error.log'
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$launcher = Join-Path $PSScriptRoot 'start-local.ps1'
function Test-LocalService {
    try {
        $request = [System.Net.WebRequest]::Create('http://127.0.0.1:8766/health')
        $request.Proxy = $null
        $request.Timeout = 1500
        $response = $request.GetResponse()
        try {
            $reader = [System.IO.StreamReader]::new($response.GetResponseStream())
            try { return $reader.ReadToEnd() -match '"revision"\s*:' }
            finally { $reader.Dispose() }
        } finally { $response.Dispose() }
    } catch { return $false }
}
while ($true) {
    if (-not (Test-LocalService)) {
        # A separate hidden process keeps the monitor alive even if the service exits.
        $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', ('"' + $launcher + '"'))
        try {
            Start-Process -FilePath $powerShell -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $log -RedirectStandardError $errorLog | Out-Null
        } catch {
            $_ | Out-String | Set-Content -LiteralPath $errorLog
        }
    }
    Start-Sleep -Seconds 10
}
