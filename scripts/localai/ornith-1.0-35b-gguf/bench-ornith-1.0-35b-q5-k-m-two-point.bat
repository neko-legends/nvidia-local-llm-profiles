@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "BENCH_WITH_SERVER=%SCRIPT_DIR%bench-with-server-ornith-1.0-35b-q5-k-m.ps1"

if not exist "%BENCH_WITH_SERVER%" (
  echo Missing benchmark wrapper:
  echo   %BENCH_WITH_SERVER%
  pause
  exit /b 1
)

echo Benchmarking Ornith 1.0 35B Q5_K_M with llama.cpp.
echo.
echo This starts llama-server on http://127.0.0.1:39189/v1, runs the saved
echo 10k and 200k prompt fixtures once each, then stops the server.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%BENCH_WITH_SERVER%"

echo.
echo Benchmark exited with code %ERRORLEVEL%.
pause
exit /b %ERRORLEVEL%
