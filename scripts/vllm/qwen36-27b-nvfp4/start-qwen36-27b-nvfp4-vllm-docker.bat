@echo off
setlocal

rem ============================================================
rem  NVIDIA Qwen3.6 27B NVFP4 vLLM launcher.
rem  Tested from a Windows host with Docker Desktop + NVIDIA GPU support.
rem  Serves an OpenAI-compatible endpoint on port 39196.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "REPO_ID=nvidia/Qwen3.6-27B-NVFP4"
set "MODEL_ALIAS=qwen36-27b-nvfp4-vllm"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined MODEL_DIR (
  set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4"
)
if not defined IMAGE set "IMAGE=vllm/vllm-openai:nightly"
set "CONTAINER_NAME=qwen36-27b-nvfp4-vllm"
set "HF_CACHE_VOLUME=qwen36-27b-nvfp4-hf-cache"
if not defined HOST_PORT set "HOST_PORT=39196"
if not defined CONTAINER_PORT set "CONTAINER_PORT=8000"
if not defined MAX_MODEL_LEN set "MAX_MODEL_LEN=200000"
if not defined MAX_NUM_SEQS set "MAX_NUM_SEQS=1"
if not defined MAX_NUM_BATCHED_TOKENS set "MAX_NUM_BATCHED_TOKENS=8192"
if not defined GPU_MEMORY_UTILIZATION set "GPU_MEMORY_UTILIZATION=0.93"
if not defined KV_CACHE_DTYPE set "KV_CACHE_DTYPE=fp8"
if not defined SAFETENSORS_LOAD_STRATEGY set "SAFETENSORS_LOAD_STRATEGY=prefetch"
if not defined VLLM_BLOCKSCALE_FP8_GEMM_FLASHINFER set "VLLM_BLOCKSCALE_FP8_GEMM_FLASHINFER=0"
if not defined VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE set "VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE=0"
set "DOCKER_RUN_ARGS=--rm -it"
if "%DETACH%"=="1" set "DOCKER_RUN_ARGS=--rm -d"
if "%KEEP_CONTAINER%"=="1" (
  set "DOCKER_RUN_ARGS=-it"
  if "%DETACH%"=="1" set "DOCKER_RUN_ARGS=-d"
)

if not defined DOCKER_CONFIG (
  set "DOCKER_CONFIG=%SCRIPT_DIR%..\..\..\.docker-tmp"
)
if not exist "%DOCKER_CONFIG%" mkdir "%DOCKER_CONFIG%"

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
  echo   scripts\localai\qwen36-27b-nvfp4-gguf\download-qwen36-27b-nvfp4.bat
  echo.
  pause
  exit /b 1
)

echo Starting %MODEL_ALIAS% with vLLM Docker
echo.
echo Desktop base URL:  http://127.0.0.1:%HOST_PORT%/v1
echo LAN base URL:      http://^<your-lan-ip^>:%HOST_PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Model source:      %MODEL_DIR%
echo Hugging Face repo: %REPO_ID%
echo Docker image:      %IMAGE%
echo HF cache volume:   %HF_CACHE_VOLUME%
echo Context:           %MAX_MODEL_LEN% tokens
echo KV cache dtype:    %KV_CACHE_DTYPE%
echo Runtime:           Windows host, Docker vLLM
echo Spec decode:       disabled in this baseline launcher
echo FlashInfer tuning:  blockscale-fp8-gemm=%VLLM_BLOCKSCALE_FP8_GEMM_FLASHINFER%, inductor-max-autotune=%VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE%
echo.
echo Close other local GPU model servers first. This profile needs most of the 5090.
echo In Hermes use an OpenAI-compatible endpoint at the Desktop base URL above.
if "%DETACH%"=="1" echo Detached mode: container will run in the background.
if "%KEEP_CONTAINER%"=="1" echo Keep container: failed containers will be preserved for logs.
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

docker volume inspect "%HF_CACHE_VOLUME%" >nul 2>&1
if %ERRORLEVEL% neq 0 (
  docker volume create "%HF_CACHE_VOLUME%" >nul
)

docker rm -f "%CONTAINER_NAME%" >nul 2>&1

docker run %DOCKER_RUN_ARGS% --gpus all ^
  --name "%CONTAINER_NAME%" ^
  -p %HOST_PORT%:%CONTAINER_PORT% ^
  -e CUDA_VISIBLE_DEVICES=0 ^
  -e CUDA_DEVICE_ORDER=PCI_BUS_ID ^
  -e VLLM_BLOCKSCALE_FP8_GEMM_FLASHINFER ^
  -e VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE ^
  -e VLLM_USE_FLASHINFER_SAMPLER=1 ^
  -e HF_TOKEN ^
  -v "%MODEL_DIR%:/model:ro" ^
  -v "%HF_CACHE_VOLUME%:/root/.cache/huggingface" ^
  --entrypoint vllm ^
  "%IMAGE%" ^
  serve /model ^
  --host 0.0.0.0 ^
  --port %CONTAINER_PORT% ^
  --served-model-name "%MODEL_ALIAS%" ^
  --tensor-parallel-size 1 ^
  --quantization modelopt ^
  --trust-remote-code ^
  --safetensors-load-strategy %SAFETENSORS_LOAD_STRATEGY% ^
  --kv-cache-dtype %KV_CACHE_DTYPE% ^
  --attention-backend flashinfer ^
  --max-model-len %MAX_MODEL_LEN% ^
  --max-num-seqs %MAX_NUM_SEQS% ^
  --max-num-batched-tokens %MAX_NUM_BATCHED_TOKENS% ^
  --gpu-memory-utilization %GPU_MEMORY_UTILIZATION% ^
  --enable-chunked-prefill ^
  --async-scheduling ^
  --enable-prefix-caching ^
  --load-format fastsafetensors ^
  --no-enable-flashinfer-autotune ^
  --reasoning-parser qwen3

echo.
echo Server exited with code %ERRORLEVEL%.
pause
