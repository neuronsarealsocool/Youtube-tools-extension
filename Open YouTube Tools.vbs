Option Explicit
Dim shell, fs, root, executable, script, command, result
Set shell = CreateObject("WScript.Shell")
Set fs = CreateObject("Scripting.FileSystemObject")
root = fs.GetParentFolderName(WScript.ScriptFullName)
executable = shell.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
script = fs.BuildPath(root, "tampermonkey\open-tools.ps1")
command = """" & executable & """ -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """"
result = shell.Run(command, 0, True)
If result <> 0 Then
    MsgBox "YouTube Tools could not start. Check .local\dev\startup.log and startup-error.log, or run Start YouTube Tools.cmd for details.", vbExclamation, "YouTube Tools"
End If
