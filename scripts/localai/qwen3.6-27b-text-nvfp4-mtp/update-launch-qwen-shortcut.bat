@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%update-launch-qwen-shortcut.ps1"

if not exist "%PS_SCRIPT%" (
    echo Missing updater:
    echo %PS_SCRIPT%
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
pause
