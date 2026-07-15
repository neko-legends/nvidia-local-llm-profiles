@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0bootstrap-cuda-13.3-portable.ps1"
exit /b %ERRORLEVEL%
