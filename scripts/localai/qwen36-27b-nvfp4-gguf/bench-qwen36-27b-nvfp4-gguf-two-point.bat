@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bench-with-server-qwen36-27b-nvfp4-gguf.ps1" %*
exit /b %ERRORLEVEL%
