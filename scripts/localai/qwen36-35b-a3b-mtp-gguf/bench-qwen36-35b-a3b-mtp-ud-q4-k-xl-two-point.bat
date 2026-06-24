@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
set "BENCH=%REPO_ROOT%\scripts\benchmarks\bench-context-ladder.ps1"
set "BASE_URL=http://127.0.0.1:39185/v1"
set "MODEL_ALIAS=qwen36-35b-a3b-mtp-ud-q4-k-xl"
set "CASE_PREFIX=qwen36-35b-a3b-mtp-ud-q4-k-xl-llamacpp-ctx200k"
set "GPU_INDEX=0"
set "MAX_TOKENS=1024"
set "RUNS=1"
set "WARMUP_RUNS=0"
set "PROMPT_TOKEN_TARGETS=10000,200000"

if not exist "%BENCH%" (
  echo Missing benchmark script:
  echo   %BENCH%
  pause
  exit /b 1
)

echo Benchmarking %MODEL_ALIAS%:
echo   %BASE_URL%
echo.
echo This runs one measured request at about 10k prompt tokens and one at 200k.
echo Make sure the llama.cpp server is already running before continuing.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& '%BENCH%' -BaseUrl '%BASE_URL%' -Model '%MODEL_ALIAS%' -CasePrefix '%CASE_PREFIX%' -GpuIndex %GPU_INDEX% -PromptTokenTargets @(%PROMPT_TOKEN_TARGETS%) -MaxTokens %MAX_TOKENS% -Runs %RUNS% -WarmupRuns %WARMUP_RUNS% -Temperature 0 -Seed 1234"

echo.
echo Benchmark exited with code %ERRORLEVEL%.
pause
