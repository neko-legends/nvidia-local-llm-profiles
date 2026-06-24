@echo off
setlocal EnableDelayedExpansion

rem ============================================================
rem  Unsloth Qwen3.6 35B A3B MTP GGUF llama.cpp launcher.
rem  Model: Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
rem  Endpoint: http://127.0.0.1:39185/v1
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "LLAMA_DIR=D:\Tools\llama.cpp-b9267-cuda13.1"
set "MODEL_PATH=%SCRIPT_DIR%models\Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"
set "MODEL_ALIAS=qwen36-35b-a3b-mtp-ud-q4-k-xl"
set "HOST=0.0.0.0"
set "PORT=39185"
set "CTX_SIZE=200000"
set "THINKING=0"

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
  for /r "%USERPROFILE%\.cache\huggingface\hub\models--unsloth--Qwen3.6-35B-A3B-MTP-GGUF\snapshots" %%F in (Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf) do (
    set "MODEL_PATH=%%~fF"
  )
)

if not exist "%MODEL_PATH%" (
  echo.
  echo ERROR: Model file not found:
  echo   Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
  echo.
  echo Download it with:
  echo   download-qwen36-35b-a3b-ud-q4-k-xl.bat
  echo.
  pause
  exit /b 1
)

set "REASONING_FLAG=--reasoning off"
if "%THINKING%"=="1" set "REASONING_FLAG=--reasoning on"

echo Starting llama.cpp server for %MODEL_ALIAS%
echo.
echo Desktop base URL:  http://127.0.0.1:%PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Model path:        %MODEL_PATH%
echo Context:           %CTX_SIZE% tokens
echo MTP speculative:   draft-mtp, draft max 2
echo Thinking mode:     %THINKING%
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
  %REASONING_FLAG% ^
  --spec-type draft-mtp ^
  --spec-draft-n-max 2

echo.
echo Server exited with code %ERRORLEVEL%.
pause
