@echo off
setlocal EnableDelayedExpansion

rem ============================================================
rem  Qwopus3.6 35B A3B Coder MTP Q5_K_M llama.cpp launcher.
rem  Endpoint: http://127.0.0.1:39191/v1
rem
rem  Set LLAMA_DIR to your llama.cpp CUDA build folder, or put
rem  llama-server.exe on PATH before running this script.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "MODEL_CACHE_DIR=%CHECKOUT_PARENT%\.local-model-cache\Jackrong\Qwopus3.6-35B-A3B-Coder-MTP-GGUF"
set "MODEL_PATH=%MODEL_CACHE_DIR%\Qwopus3.6-35B-A3B-Coder-MTP-Q5_K_M.gguf"
set "MODEL_ALIAS=qwopus3.6-35b-a3b-coder-mtp-q5-k-m"
set "HOST=0.0.0.0"
set "PORT=39191"
set "CTX_SIZE=200000"
set "THINKING=0"
if not defined SPEC_TYPE set "SPEC_TYPE=draft-mtp"
if not defined SPEC_DRAFT_N_MAX set "SPEC_DRAFT_N_MAX=2"
set "SPEC_ARGS=--spec-type %SPEC_TYPE% --spec-draft-n-max %SPEC_DRAFT_N_MAX% --spec-draft-p-min 0.0"
if /i "%SPEC_TYPE%"=="ngram-mod,draft-mtp" set "SPEC_ARGS=%SPEC_ARGS% --spec-ngram-mod-n-match 24 --spec-ngram-mod-n-min 48 --spec-ngram-mod-n-max 64"

set "LLAMA_SERVER="
if defined LLAMA_DIR (
  if exist "%LLAMA_DIR%\llama-server.exe" set "LLAMA_SERVER=%LLAMA_DIR%\llama-server.exe"
)

if not defined LLAMA_SERVER (
  for /f "usebackq delims=" %%F in (`where llama-server.exe 2^>nul`) do (
    if not defined LLAMA_SERVER set "LLAMA_SERVER=%%F"
  )
)

if not defined LLAMA_SERVER (
  echo.
  echo ERROR: llama-server.exe was not found.
  echo.
  echo Set LLAMA_DIR to your llama.cpp CUDA build folder, for example:
  echo   set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
  echo Or add llama-server.exe to PATH.
  echo.
  pause
  exit /b 1
)

for %%I in ("%LLAMA_SERVER%") do set "LLAMA_DIR=%%~dpI"

if not exist "%MODEL_PATH%" (
  echo.
  echo ERROR: Model file not found:
  echo   %MODEL_PATH%
  echo.
  echo Download it with:
  echo   download-qwopus3.6-35b-a3b-coder-mtp-q5-k-m.bat
  echo.
  pause
  exit /b 1
)

set "REASONING_FLAG=--reasoning off"
if "%THINKING%"=="1" set "REASONING_FLAG=--reasoning on"

echo Starting llama.cpp server for %MODEL_ALIAS%
echo.
echo Desktop base URL:  http://127.0.0.1:%PORT%/v1
echo LAN base URL:      http://^<your-lan-ip^>:%PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Model path:        %MODEL_PATH%
echo Context:           %CTX_SIZE% tokens
echo MTP speculative:   %SPEC_TYPE%, draft max %SPEC_DRAFT_N_MAX%
echo Thinking mode:     %THINKING%
echo.
echo Press Ctrl+C in this window to stop the server.
echo.

cd /d "%LLAMA_DIR%"

"%LLAMA_SERVER%" ^
  --model "%MODEL_PATH%" ^
  --alias "%MODEL_ALIAS%" ^
  --host %HOST% ^
  --port %PORT% ^
  --device CUDA0 ^
  --gpu-layers all ^
  --gpu-layers-draft all ^
  --ctx-size %CTX_SIZE% ^
  --cache-type-k q4_0 ^
  --cache-type-v q4_0 ^
  --cache-type-k-draft q4_0 ^
  --cache-type-v-draft q4_0 ^
  --flash-attn on ^
  --parallel 1 ^
  --cont-batching ^
  --jinja ^
  --metrics ^
  --slots ^
  %REASONING_FLAG% ^
  %SPEC_ARGS%

echo.
echo Server exited with code %ERRORLEVEL%.
pause
