@echo off
set SCRIPT_DIR=%~dp0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Run-ValidationSuite.ps1" -SmokeSeconds 8
pause

