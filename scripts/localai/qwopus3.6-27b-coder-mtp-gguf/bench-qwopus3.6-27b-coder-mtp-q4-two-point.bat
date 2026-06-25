@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass ^
  -File "%SCRIPT_DIR%bench-with-server-qwopus3.6-27b-coder-mtp-q4.ps1"

if errorlevel 1 (
  echo.
  echo Qwopus Q4 two-point benchmark failed.
  pause
  exit /b 1
)

echo.
echo Qwopus Q4 two-point benchmark complete.
pause
