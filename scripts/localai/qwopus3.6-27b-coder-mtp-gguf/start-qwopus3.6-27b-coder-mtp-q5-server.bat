@echo off
setlocal

rem ============================================================
rem  CONFIGURE: Set LLAMA_DIR to your llama.cpp CUDA build folder.
rem  It must contain llama-server.exe.
rem
rem  Set MODEL_PATH to the full path of your downloaded .gguf file.
rem
rem  The defaults below match the layout installed by install-to-LocalAI.bat
rem  (model in a "models" subfolder next to this script).
rem  Edit if you store things differently.
rem
rem  THINKING toggle:
rem    THINKING=0  Disable Qwen3 reasoning blocks (--reasoning off).
rem                The model goes straight to the answer with no CoT preamble.
rem                Faster time-to-answer for agentic coding loops. The model
rem                card benchmarks this mode: SWE-bench Verified 67% at ~100 tok/s.
rem
rem    THINKING=1  Enable reasoning blocks (--reasoning on).
rem                The model generates a thinking block before the answer.
rem                Higher raw tok/s (structures text is easier for speculative
rem                drafts to predict) but adds latency before useful output.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "LLAMA_DIR=D:\Tools\llama.cpp-b9267-cuda13.1"
set "MODEL_PATH=%SCRIPT_DIR%models\Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf"
set "MODEL_ALIAS=qwopus3.6-27b-coder-mtp-q5-k-m"
set "HOST=0.0.0.0"
set "PORT=39182"
rem RTX 5090 benchmark profile: leaves room for 200K+ prompt-token tests plus generation.
rem Lower CTX_SIZE (e.g. 32768 or 65536) if startup fails or you have less VRAM.
set "CTX_SIZE=262144"

rem ============================================================
rem  Toggle: thinking mode (0 = off, 1 = on)
rem  Default: 0 (no-think, faster time-to-answer for coding)
rem ============================================================
set "THINKING=0"

if not exist "%LLAMA_DIR%\llama-server.exe" (
  echo.
  echo ERROR: llama-server.exe not found at:
  echo   %LLAMA_DIR%
  echo.
  echo Edit LLAMA_DIR at the top of this script to point at your
  echo llama.cpp CUDA build. Download llama.cpp pre-built binaries from:
  echo   https://github.com/ggml-org/llama.cpp/releases
  echo Choose the win-cuda build matching your CUDA version.
  echo.
  pause
  exit /b 1
)

if not exist "%MODEL_PATH%" (
  echo.
  echo ERROR: Model file not found at:
  echo   %MODEL_PATH%
  echo.
  echo Edit MODEL_PATH at the top of this script, or download the model with:
  echo   download-qwopus3.6-27B-Coder-MTP-Q5.bat
  echo.
  pause
  exit /b 1
)

echo Starting llama.cpp server for %MODEL_ALIAS%
echo.
echo Desktop base URL:  http://127.0.0.1:%PORT%/v1
echo LAN base URL:      http://^<your-lan-ip^>:%PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Context:           %CTX_SIZE% tokens
echo MTP speculative:   ngram-mod + draft-mtp, draft max 2
echo.
if "%THINKING%"=="0" (
  echo Thinking mode:     OFF --reasoning off
  echo.
  echo The model goes straight to answers with no CoT preamble.
  echo Faster time-to-answer for agentic coding; benchmarked by the
  echo model card at SWE-bench Verified 67%%.
) else (
  echo Thinking mode:     ON --reasoning on
  echo.
  echo The model generates a reasoning block before the answer.
)
echo.
echo In Hermes use:
echo   Provider/API: OpenAI-compatible chat completions
echo   API key:      none or any placeholder if required
echo   Model:        %MODEL_ALIAS%
echo.
echo Press Ctrl+C in this window to stop the server.
echo.

rem --- Build the reasoning flag ---
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