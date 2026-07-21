@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-llama-b10068-win-cuda13.ps1" %*
exit /b %ERRORLEVEL%
