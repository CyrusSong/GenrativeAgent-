@echo off
set "PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;%PATH%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-simulation.ps1"
pause
