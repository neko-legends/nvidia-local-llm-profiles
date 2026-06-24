@echo off
setlocal

rem ============================================================
rem  NVIDIA Qwen3.6 35B A3B NVFP4 MoE vLLM launcher.
rem  Serves an OpenAI-compatible endpoint on port 39184.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "REPO_ID=nvidia/Qwen3.6-35B-A3B-NVFP4"
set "MODEL_ALIAS=qwen36-35b-a3b-nvfp4"
set "IMAGE=vllm/vllm-openai:nightly"
set "CONTAINER_NAME=qwen36-35b-a3b-nvfp4-vllm"
set "HF_CACHE_VOLUME=qwen36-35b-a3b-nvfp4-hf-cache"
set "HOST_PORT=39184"
set "CONTAINER_PORT=8000"
set "MAX_MODEL_LEN=200000"
set "MAX_NUM_SEQS=1"
set "MAX_NUM_BATCHED_TOKENS=8192"
set "GPU_MEMORY_UTILIZATION=0.93"
set "KV_CACHE_DTYPE=fp8"

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

echo Starting %MODEL_ALIAS% with vLLM Docker
echo.
echo Desktop base URL:  http://127.0.0.1:%HOST_PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Hugging Face repo: %REPO_ID%
echo Docker image:      %IMAGE%
echo HF cache volume:   %HF_CACHE_VOLUME%
echo Context:           %MAX_MODEL_LEN% tokens
echo KV cache dtype:    %KV_CACHE_DTYPE%
echo.
echo Close other local GPU model servers first. This profile needs most of the 5090.
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

docker run --rm -it --gpus all ^
  --name "%CONTAINER_NAME%" ^
  -p %HOST_PORT%:%CONTAINER_PORT% ^
  -e CUDA_VISIBLE_DEVICES=0 ^
  -e CUDA_DEVICE_ORDER=PCI_BUS_ID ^
  -e VLLM_NVFP4_GEMM_BACKEND=flashinfer-cutlass ^
  -e VLLM_USE_FLASHINFER_SAMPLER=1 ^
  -e HF_TOKEN ^
  -v "%HF_CACHE_VOLUME%:/root/.cache/huggingface" ^
  --entrypoint vllm ^
  "%IMAGE%" ^
  serve "%REPO_ID%" ^
  --host 0.0.0.0 ^
  --port %CONTAINER_PORT% ^
  --served-model-name "%MODEL_ALIAS%" ^
  --tensor-parallel-size 1 ^
  --quantization modelopt ^
  --trust-remote-code ^
  --kv-cache-dtype %KV_CACHE_DTYPE% ^
  --attention-backend flashinfer ^
  --moe-backend marlin ^
  --max-model-len %MAX_MODEL_LEN% ^
  --max-num-seqs %MAX_NUM_SEQS% ^
  --max-num-batched-tokens %MAX_NUM_BATCHED_TOKENS% ^
  --gpu-memory-utilization %GPU_MEMORY_UTILIZATION% ^
  --enable-chunked-prefill ^
  --async-scheduling ^
  --enable-prefix-caching ^
  --load-format fastsafetensors ^
  --reasoning-parser qwen3 ^
  --tool-call-parser qwen3_xml ^
  --enable-auto-tool-choice

echo.
echo Server exited with code %ERRORLEVEL%.
pause
