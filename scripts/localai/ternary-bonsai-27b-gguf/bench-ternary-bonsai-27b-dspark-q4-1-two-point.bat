@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
set "BENCH=%REPO_ROOT%\scripts\benchmarks\bench-ternary-bonsai-dspark-two-point.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%BENCH%"
exit /b %ERRORLEVEL%
