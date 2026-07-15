@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-buun-dflash-sm120-runtime.ps1"
exit /b %ERRORLEVEL%
