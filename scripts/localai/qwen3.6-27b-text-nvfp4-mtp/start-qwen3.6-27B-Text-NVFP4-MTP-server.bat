@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Start-Qwen3.6-27B-Text-NVFP4-MTP-vLLM.ps1"

if not exist "%PS_SCRIPT%" (
    echo Missing launcher:
    echo %PS_SCRIPT%
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*

echo.
echo Qwen3.6 Text NVFP4 MTP server stopped.
pause
