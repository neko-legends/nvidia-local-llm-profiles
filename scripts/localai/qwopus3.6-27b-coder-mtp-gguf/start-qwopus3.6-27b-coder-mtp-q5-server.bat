@echo off
setlocal

set "LLAMA_DIR=D:\Tools\llama.cpp-b9267-cuda13.1"
set "MODEL_PATH=D:\Tools\LocalAI\models\Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf"
set "MODEL_ALIAS=qwopus3.6-27b-coder-mtp-q5-k-m"
set "HOST=0.0.0.0"
set "PORT=39182"
rem RTX 5090 benchmark profile: leave room for 200K prompt-token tests plus generation.
set "CTX_SIZE=262144"

if not exist "%LLAMA_DIR%\llama-server.exe" (
  echo Missing llama-server.exe at "%LLAMA_DIR%\llama-server.exe"
  pause
  exit /b 1
)

if not exist "%MODEL_PATH%" (
  echo Missing model at "%MODEL_PATH%"
  echo.
  echo Put Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf in:
  echo D:\Tools\LocalAI\models
  pause
  exit /b 1
)

echo Starting llama.cpp server for %MODEL_ALIAS%
echo.
echo Hermes Desktop base URL:  http://127.0.0.1:%PORT%/v1
echo Hermes Client LAN:        http://192.168.68.73:%PORT%/v1
echo Hermes Client Tailscale:  http://100.64.131.86:%PORT%/v1
echo Model id:                 %MODEL_ALIAS%
echo Context:                  %CTX_SIZE% tokens
echo MTP speculative decode:   ngram-mod + draft-mtp, draft max 2
echo.
echo In Hermes use:
echo Provider/API: OpenAI-compatible chat completions
echo API key:      none or any placeholder if required
echo Model:        %MODEL_ALIAS%
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
  --spec-type ngram-mod,draft-mtp ^
  --spec-draft-n-max 2 ^
  --spec-draft-p-min 0.0 ^
  --spec-ngram-mod-n-match 24 ^
  --spec-ngram-mod-n-min 48 ^
  --spec-ngram-mod-n-max 64

echo.
echo Server exited with code %ERRORLEVEL%.
pause
