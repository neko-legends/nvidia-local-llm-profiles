@echo off
setlocal

rem ============================================================
rem  AEON Qwen3.6 27B Multimodal NVFP4 MTP-XS vLLM launcher.
rem  Tested on RTX 5090 32GB / Windows / Docker Desktop.
rem  Serves an OpenAI-compatible endpoint on port 39183.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "MODEL_DIR=%SCRIPT_DIR%models\aeon-ultimate-multimodal-nvfp4-mtp-xs"
set "MODEL_VOLUME=aeon-qwen36-mtp-xs-model"
set "MODEL_ALIAS=aeon-qwen36-27b-multimodal-nvfp4-mtp-xs"
set "IMAGE=vllm/vllm-openai:latest"
set "CONTAINER_NAME=aeon-qwen36-27b-mtp-xs-vllm"
set "HOST_PORT=39183"
set "CONTAINER_PORT=8000"
set "MAX_MODEL_LEN=200000"
set "MAX_NUM_SEQS=1"
set "MAX_NUM_BATCHED_TOKENS=8192"
set "GPU_MEMORY_UTILIZATION=0.93"
set "KV_CACHE_DTYPE=fp8"

where docker >nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo.
  echo ERROR: docker was not found in PATH.
  echo Install Docker Desktop with NVIDIA GPU support, then retry.
  echo.
  pause
  exit /b 1
)

if not exist "%MODEL_DIR%\config.json" (
  echo.
  echo ERROR: Model snapshot not found at:
  echo   %MODEL_DIR%
  echo.
  echo Download it first with:
  echo   download-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.bat
  echo.
  pause
  exit /b 1
)

echo Starting AEON vLLM server for %MODEL_ALIAS%
echo.
echo Desktop base URL:  http://127.0.0.1:%HOST_PORT%/v1
echo LAN base URL:      http://^<your-lan-ip^>:%HOST_PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Docker image:      %IMAGE%
echo Docker volume:     %MODEL_VOLUME%
echo Context:           %MAX_MODEL_LEN% tokens
echo KV cache dtype:    %KV_CACHE_DTYPE%
echo Spec decode:       qwen3_5_mtp, speculative tokens 3
echo.
echo In Hermes use:
echo   Provider/API: OpenAI-compatible chat completions
echo   API key:      none or any placeholder if required
echo   Model:        %MODEL_ALIAS%
echo.
echo Press Ctrl+C in this window to stop the server.
echo.

docker image inspect "%IMAGE%" >nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo Pulling %IMAGE% ...
  docker pull "%IMAGE%"
  if errorlevel 1 (
    echo.
    echo Docker pull failed.
    pause
    exit /b 1
  )
)

docker volume inspect "%MODEL_VOLUME%" >nul 2>&1
if %ERRORLEVEL% neq 0 (
  docker volume create "%MODEL_VOLUME%" >nul
)

set "NEED_COPY=0"
docker run --rm -v "%MODEL_VOLUME%:/model:ro" alpine:latest test -f /model/config.json >nul 2>&1
if %ERRORLEVEL% neq 0 set "NEED_COPY=1"
if /I "%REFRESH_MODEL_VOLUME%"=="1" set "NEED_COPY=1"

if "%NEED_COPY%"=="1" (
  echo Preparing Docker model volume. This copies about 21GB once.
  docker run --rm ^
    -v "%MODEL_DIR%:/src:ro" ^
    -v "%MODEL_VOLUME%:/dst" ^
    alpine:latest ^
    sh -c "rm -rf /dst/* && cp -a /src/. /dst/ && test -f /dst/config.json"
  if errorlevel 1 (
    echo.
    echo Failed to populate Docker model volume.
    pause
    exit /b 1
  )
)

docker rm -f "%CONTAINER_NAME%" >nul 2>&1

docker run --rm -it --gpus all ^
  --name "%CONTAINER_NAME%" ^
  -p %HOST_PORT%:%CONTAINER_PORT% ^
  -e CUDA_VISIBLE_DEVICES=0 ^
  -e CUDA_DEVICE_ORDER=PCI_BUS_ID ^
  -e VLLM_NVFP4_GEMM_BACKEND=flashinfer-cutlass ^
  -e VLLM_USE_FLASHINFER_MOE_FP4=0 ^
  -e VLLM_USE_FLASHINFER_SAMPLER=1 ^
  -v "%MODEL_VOLUME%:/model:ro" ^
  --entrypoint vllm ^
  "%IMAGE%" ^
  serve /model ^
  --host 0.0.0.0 ^
  --port %CONTAINER_PORT% ^
  --served-model-name "%MODEL_ALIAS%" ^
  --quantization modelopt ^
  --trust-remote-code ^
  --kv-cache-dtype %KV_CACHE_DTYPE% ^
  --limit-mm-per-prompt "{""image"":4,""video"":2}" ^
  --mm-encoder-tp-mode data ^
  --max-model-len %MAX_MODEL_LEN% ^
  --max-num-seqs %MAX_NUM_SEQS% ^
  --max-num-batched-tokens %MAX_NUM_BATCHED_TOKENS% ^
  --gpu-memory-utilization %GPU_MEMORY_UTILIZATION% ^
  --enable-chunked-prefill ^
  --enable-prefix-caching ^
  --reasoning-parser qwen3 ^
  --tool-call-parser qwen3_coder ^
  --enable-auto-tool-choice ^
  --speculative-config "{""method"":""qwen3_5_mtp"",""num_speculative_tokens"":3}"

echo.
echo Server exited with code %ERRORLEVEL%.
pause
