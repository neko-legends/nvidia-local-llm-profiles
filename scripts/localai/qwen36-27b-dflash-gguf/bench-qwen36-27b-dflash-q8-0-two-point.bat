@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\benchmarks\bench-qwen36-27b-dflash-two-point.ps1" %*
exit /b %ERRORLEVEL%
