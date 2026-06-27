@echo off
set SCRIPT_DIR=%~dp0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%FortClipLite.ps1" -SmokeTest -SmokeSeconds 8 -SmokeCaptureMode gdigrab -SmokeEncoder libx264 -SmokeAudioMode silent -KeepSmokeClip
pause

