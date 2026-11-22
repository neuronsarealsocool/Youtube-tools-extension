Option Explicit
Dim shell, files, background, powershell, command, result
Set shell = CreateObject("WScript.Shell")
Set files = CreateObject("Scripting.FileSystemObject")
If WScript.Arguments.Count <> 1 Then WScript.Quit 2
background = WScript.Arguments(0)
If Not files.FileExists(background) Then WScript.Quit 3
powershell = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
command = Chr(34) & powershell & Chr(34) & " -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File " & Chr(34) & background & Chr(34)
' Start hidden before console allocation; keep Task Scheduler tracking the monitor.
result = shell.Run(command, 0, True)
WScript.Quit result
