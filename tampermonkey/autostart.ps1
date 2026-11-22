param([ValidateSet('Enable', 'Disable')][string]$Action = 'Enable')
$ErrorActionPreference = 'Stop'
$taskName = 'YouTube Tools Local'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$background = Join-Path $PSScriptRoot 'start-background.ps1'
$powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f $background
$legacyCommand = '"{0}" {1}' -f $powershell, $arguments
$hiddenLauncher = Join-Path $PSScriptRoot 'start-hidden.vbs'
$wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
$hiddenArguments = '//B //Nologo "{0}" "{1}"' -f $hiddenLauncher, $background
$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$isLegacy = $existing -and $existing.Actions.Count -eq 1 -and $existing.Actions[0].Arguments -eq $arguments -and $existing.Actions[0].Execute -eq $powershell
$isHidden = $existing -and $existing.Actions.Count -eq 1 -and $existing.Actions[0].Arguments -eq $hiddenArguments -and $existing.Actions[0].Execute -eq $wscript
if ($existing -and -not ($isLegacy -or $isHidden)) {
    throw 'The startup task belongs to a different YouTube Tools folder. Disable it from that folder first.'
}

if ($Action -eq 'Enable') {
    if (-not (Test-Path -LiteralPath $background)) { throw 'The background launcher is missing.' }
    if (-not (Test-Path -LiteralPath $hiddenLauncher)) { throw 'The hidden launcher is missing.' }
    $account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $taskAction = New-ScheduledTaskAction -Execute $wscript -Argument $hiddenArguments
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $account
    $trigger.Delay = 'PT30S'
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Seconds 0) -MultipleInstances IgnoreNew -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
    $principal = New-ScheduledTaskPrincipal -UserId $account -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $trigger -Settings $settings -Principal $principal -Description 'Starts and monitors the local YouTube Tools service.' -Force | Out-Null
    $legacy = (Get-ItemProperty -LiteralPath $runKey -Name $taskName -ErrorAction SilentlyContinue).$taskName
    if ($legacy -eq $legacyCommand) { Remove-ItemProperty -LiteralPath $runKey -Name $taskName }
    Write-Host 'YouTube Tools will start for your Windows account when you sign in.'
    Write-Host 'If you move the project folder, disable startup here, then enable it from the new folder.'
} else {
    if ($existing) {
        if ($existing.State -eq 'Running') { Stop-ScheduledTask -TaskName $taskName }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    $legacy = (Get-ItemProperty -LiteralPath $runKey -Name $taskName -ErrorAction SilentlyContinue).$taskName
    if ($legacy -and $legacy -ne $legacyCommand) { throw 'The legacy startup entry belongs to another YouTube Tools folder.' }
    if ($legacy) { Remove-ItemProperty -LiteralPath $runKey -Name $taskName }
    Write-Host 'YouTube Tools automatic startup is disabled for your Windows account.'
}
