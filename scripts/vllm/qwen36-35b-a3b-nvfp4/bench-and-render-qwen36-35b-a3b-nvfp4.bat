@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

call "%SCRIPT_DIR%bench-qwen36-35b-a3b-nvfp4-two-point.bat"
if errorlevel 1 exit /b %ERRORLEVEL%

python "%SCRIPT_DIR%..\..\..\scripts\benchmarks\render-qwen35-moe-comparison-chart.py"
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo Chart written to:
echo   %SCRIPT_DIR%..\..\..\assets\images\rtx-5090-qwen35-moe-vs-qwopus.svg
echo.
pause
