@echo off
setlocal EnableDelayedExpansion

rem ============================================================
rem  DeepReinforce Ornith 1.0 35B GGUF llama.cpp launcher.
rem  Model: ornith-1.0-35b-Q5_K_M.gguf
rem  Endpoint: http://127.0.0.1:39189/v1
rem ============================================================
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "LLAMA_DIR=D:\Tools\llama.cpp-b9267-cuda13.1"
set "MODEL_PATH=%CHECKOUT_PARENT%\.local-model-cache\deepreinforce-ai\Ornith-1.0-35B-GGUF\ornith-1.0-35b-Q5_K_M.gguf"
set "MODEL_ALIAS=ornith-1.0-35b-q5-k-m"
set "HOST=0.0.0.0"
set "PORT=39189"
rem RTX 5090 profile: 256k context for the Q5_K_M quant.
set "CTX_SIZE=262144"

rem Ornith is a reasoning model. Keep reasoning on by default so the model follows
rem its native template; set THINKING=0 for lower-latency no-think experiments.
set "THINKING=1"

if not exist "%LLAMA_DIR%\llama-server.exe" (
  echo.
  echo ERROR: llama-server.exe not found at:
  echo   %LLAMA_DIR%
  echo.
  echo Edit LLAMA_DIR at the top of this script to point at your llama.cpp CUDA build.
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
  echo   download-ornith-1.0-35b-q5-k-m.bat
  echo.
  pause
  exit /b 1
)

set "REASONING_FLAG=--reasoning on"
if "%THINKING%"=="0" set "REASONING_FLAG=--reasoning off"

echo Starting llama.cpp server for %MODEL_ALIAS%
echo.
echo Desktop base URL:  http://127.0.0.1:%PORT%/v1
echo LAN base URL:      http://^<your-lan-ip^>:%PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Model path:        %MODEL_PATH%
echo Context:           %CTX_SIZE% tokens
echo Thinking mode:     %THINKING%
echo.
echo In Hermes use:
echo   Provider/API: OpenAI-compatible chat completions
echo   API key:      none or any placeholder if required
echo   Model:        %MODEL_ALIAS%
echo.
echo Press Ctrl+C in this window to stop the server.
echo.

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
  %REASONING_FLAG%

echo.
echo Server exited with code %ERRORLEVEL%.
pause
