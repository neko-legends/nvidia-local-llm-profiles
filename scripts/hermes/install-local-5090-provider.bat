@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install-local-5090-provider.ps1" %*
exit /b %ERRORLEVEL%
