@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

echo ============================================================
echo  Qwen3.6 27B NVFP4 GGUF baseline: no MTP
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bench-with-server-qwen36-27b-nvfp4-gguf.ps1" -SpecType none %*
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo ============================================================
echo  Qwen3.6 27B NVFP4 GGUF speculative: draft-mtp n=2
echo ============================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%bench-with-server-qwen36-27b-nvfp4-gguf.ps1" -SpecType draft-mtp -SpecDraftNMax 2 %*
exit /b %ERRORLEVEL%
