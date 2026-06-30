@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass ^
  -File "%SCRIPT_DIR%bench-with-server-qwopus3.6-35b-a3b-coder-mtp-q4-k-m.ps1"

if errorlevel 1 (
  echo.
  echo Qwopus3.6 35B A3B Coder MTP Q4_K_M two-point benchmark failed.
  pause
  exit /b 1
)

echo.
echo Qwopus3.6 35B A3B Coder MTP Q4_K_M two-point benchmark complete.
pause
