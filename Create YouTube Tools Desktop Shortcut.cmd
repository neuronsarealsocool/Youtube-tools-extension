@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tampermonkey\create-desktop-shortcut.ps1"
echo.
pause
