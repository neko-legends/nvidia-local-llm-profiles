@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\prism-ml\Ternary-Bonsai-27B-gguf"
if not defined MODEL_PATH set "MODEL_PATH=%MODEL_DIR%\Ternary-Bonsai-27B-Q2_0.gguf"
if not defined DRAFT_PATH set "DRAFT_PATH=%MODEL_DIR%\Ternary-Bonsai-27B-dspark-Q4_1.gguf"
if not defined PRISM_LLAMA_DIR set "PRISM_LLAMA_DIR=%CHECKOUT_PARENT%\.llama-runtimes\prism-62061f9-sm120-win-cuda12.8"
if not defined USE_DSPARK set "USE_DSPARK=1"
if not defined CTX_SIZE if "%USE_DSPARK%"=="1" (set "CTX_SIZE=16384") else (set "CTX_SIZE=262144")
if not defined PORT set "PORT=39199"
set "MODEL_ALIAS=ternary-bonsai-27b-dspark-q4-1"

if not exist "%PRISM_LLAMA_DIR%\llama-server.exe" (
  echo ERROR: Blackwell-native PrismML runtime not found. Run build-prism-llamacpp-sm120-runtime.bat first.
  exit /b 1
)
if not exist "%MODEL_PATH%" (
  echo ERROR: Target model not found. Run download-ternary-bonsai-27b-dspark-q4-1.bat first.
  exit /b 1
)
if "%USE_DSPARK%"=="1" if not exist "%DRAFT_PATH%" (
  echo ERROR: DSpark drafter not found: %DRAFT_PATH%
  exit /b 1
)

echo Model:   %MODEL_ALIAS%
echo URL:     http://127.0.0.1:%PORT%/v1
set "DRAFT_ARGS="
if "%USE_DSPARK%"=="1" set DRAFT_ARGS=-md "%DRAFT_PATH%" --device-draft CUDA0 -ngld 999 --cache-type-k-draft q4_0 --cache-type-v-draft q4_0 --spec-type draft-dspark --spec-draft-n-max 4
echo Context: %CTX_SIZE%  DSpark: %USE_DSPARK%  KV: q4_0
cd /d "%PRISM_LLAMA_DIR%"
"%PRISM_LLAMA_DIR%\llama-server.exe" -m "%MODEL_PATH%" --alias "%MODEL_ALIAS%" --host 0.0.0.0 --port %PORT% --device CUDA0 -ngl 999 -fa on -c %CTX_SIZE% -np 1 --cache-type-k q4_0 --cache-type-v q4_0 --jinja --metrics --slots --reasoning-budget 0 --reasoning-format none %DRAFT_ARGS%
exit /b %ERRORLEVEL%
