@echo off
setlocal

rem ============================================================
rem  Qwopus3.6 27B Coder MTP Q4_K_M GGUF llama.cpp server.
rem
rem  This is the lower-VRAM variant to try when Q5_K_M cannot hold
rem  the desired long context on a single 32GB RTX 5090.
rem
rem  Set LLAMA_DIR to your llama.cpp CUDA build folder.
rem  It must contain llama-server.exe.
rem
rem  MODEL_PATH defaults to the shared local model cache next to
rem  the Q5_K_M file. Edit if you store things differently.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "LLAMA_DIR=D:\Tools\llama.cpp-b9267-cuda13.1"
for %%I in ("%SCRIPT_DIR%..\..\..\..\.local-model-cache\Jackrong\Qwopus3.6-27B-Coder-MTP-GGUF") do set "MODEL_CACHE_DIR=%%~fI"
set "MODEL_PATH=%MODEL_CACHE_DIR%\Qwopus3.6-27B-Coder-MTP-Q4_K_M.gguf"
set "MODEL_ALIAS=qwopus3.6-27b-coder-mtp-q4-k-m"
set "HOST=0.0.0.0"
set "PORT=39186"

rem Long-context profile for a 32GB RTX 5090.
rem Lower CTX_SIZE if startup fails or VRAM pressure is still too high.
set "CTX_SIZE=262144"

rem Toggle: 0 = no-think, 1 = reasoning on.
set "THINKING=0"

if not exist "%LLAMA_DIR%\llama-server.exe" (
  echo.
  echo ERROR: llama-server.exe not found at:
  echo   %LLAMA_DIR%
  echo.
  echo Edit LLAMA_DIR at the top of this script.
  echo.
  pause
  exit /b 1
)

if not exist "%MODEL_PATH%" (
  echo.
  echo ERROR: Model file not found at:
  echo   %MODEL_PATH%
  echo.
  echo Download it with:
  echo   download-qwopus3.6-27B-Coder-MTP-Q4.bat
  echo.
  pause
  exit /b 1
)

echo Starting llama.cpp server for %MODEL_ALIAS%
echo.
echo Desktop base URL:  http://127.0.0.1:%PORT%/v1
echo LAN base URL:      http://^<your-lan-ip^>:%PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Model path:        %MODEL_PATH%
echo Context:           %CTX_SIZE% tokens
echo MTP speculative:   ngram-mod + draft-mtp, draft max 2
echo KV cache:          q4_0 / q4_0
echo.
if "%THINKING%"=="0" (
  echo Thinking mode:     OFF --reasoning off
) else (
  echo Thinking mode:     ON --reasoning on
)
echo.
echo Press Ctrl+C in this window to stop the server.
echo.

set "REASONING_FLAG=--reasoning off"
if "%THINKING%"=="1" set "REASONING_FLAG=--reasoning on"

cd /d "%LLAMA_DIR%"

"%LLAMA_DIR%\llama-server.exe" ^
  --model "%MODEL_PATH%" ^
  --alias "%MODEL_ALIAS%" ^
  --host %HOST% ^
  --port %PORT% ^
  --device CUDA0 ^
  --gpu-layers all ^
  --ctx-size %CTX_SIZE% ^
  --cache-type-k q4_0 ^
  --cache-type-v q4_0 ^
  --flash-attn on ^
  --parallel 1 ^
  --cont-batching ^
  --jinja ^
  --metrics ^
  --slots ^
  %REASONING_FLAG% ^
  --spec-type ngram-mod,draft-mtp ^
  --spec-draft-n-max 2 ^
  --spec-draft-p-min 0.0 ^
  --spec-ngram-mod-n-match 24 ^
  --spec-ngram-mod-n-min 48 ^
  --spec-ngram-mod-n-max 64

echo.
echo Server exited with code %ERRORLEVEL%.
pause
