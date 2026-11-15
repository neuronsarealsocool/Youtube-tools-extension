$ErrorActionPreference = 'Stop'
$background = Join-Path $PSScriptRoot 'start-background.ps1'
$powerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
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
try {
    if (-not (Test-LocalService)) {
        Write-Host 'Starting YouTube Tools...'
        $task = Get-ScheduledTask -TaskName 'YouTube Tools Local' -ErrorAction SilentlyContinue
        if ($task -and $task.Actions[0].Arguments.IndexOf($background, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            if ($task.State -ne 'Running') { Start-ScheduledTask -TaskName 'YouTube Tools Local' }
        } else {
            Start-Process -FilePath $powerShell -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', ('"' + $background + '"')) -WindowStyle Hidden
        }
        for ($i = 0; $i -lt 60 -and -not (Test-LocalService); $i++) { Start-Sleep -Seconds 1 }
        if (-not (Test-LocalService)) { throw 'The service did not start. Check .local\dev\startup.log or run Start YouTube Tools.cmd for details.' }
    }
    Start-Process 'https://www.youtube.com/'
} catch {
    Write-Host "YouTube Tools could not start: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
