@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
set "BENCH=%REPO_ROOT%\scripts\benchmarks\bench-openai-chat-endpoint.ps1"
set "BASE_URL=http://127.0.0.1:39184/v1"
set "MODEL_ALIAS=qwen36-35b-a3b-nvfp4"
set "CASE_PREFIX=qwen36-35b-a3b-nvfp4-vllm-fp8kv-ctx200k"
set "GPU_INDEX=0"
set "MAX_TOKENS=1024"
set "RUNS=1"
set "WARMUP_RUNS=0"
set "PROMPT_10K=benchmarks\prompts\book-context-10k.txt"
set "PROMPT_200K=benchmarks\prompts\book-context-200k.txt"

if not exist "%BENCH%" (
  echo Missing benchmark script:
  echo   %BENCH%
  pause
  exit /b 1
)

if not exist "%REPO_ROOT%\%PROMPT_10K%" (
  echo Missing prompt fixture:
  echo   %REPO_ROOT%\%PROMPT_10K%
  pause
  exit /b 1
)

if not exist "%REPO_ROOT%\%PROMPT_200K%" (
  echo Missing prompt fixture:
  echo   %REPO_ROOT%\%PROMPT_200K%
  pause
  exit /b 1
)

echo Benchmarking %MODEL_ALIAS%:
echo   %BASE_URL%
echo.
echo This runs one measured request with the saved 10k prompt fixture and
echo one measured request with the saved 200k prompt fixture.
echo Make sure the vLLM server is already running before continuing.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& '%BENCH%' -BaseUrl '%BASE_URL%' -Model '%MODEL_ALIAS%' -CaseName '%CASE_PREFIX%-prompt10k-gen%MAX_TOKENS%' -GpuIndex %GPU_INDEX% -MaxTokens %MAX_TOKENS% -Runs %RUNS% -WarmupRuns %WARMUP_RUNS% -Temperature 0 -Seed 1234 -PromptFile '%PROMPT_10K%' -PromptStyle BookContext -TargetPromptTokens 10000"
if errorlevel 1 goto bench_failed

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& '%BENCH%' -BaseUrl '%BASE_URL%' -Model '%MODEL_ALIAS%' -CaseName '%CASE_PREFIX%-prompt200k-gen%MAX_TOKENS%' -GpuIndex %GPU_INDEX% -MaxTokens %MAX_TOKENS% -Runs %RUNS% -WarmupRuns %WARMUP_RUNS% -Temperature 0 -Seed 1234 -PromptFile '%PROMPT_200K%' -PromptStyle BookContext -TargetPromptTokens 200000"
if errorlevel 1 goto bench_failed

echo.
echo Benchmark exited with code 0.
pause
exit /b 0

:bench_failed
echo.
echo Benchmark exited with code %ERRORLEVEL%.
pause
exit /b %ERRORLEVEL%
