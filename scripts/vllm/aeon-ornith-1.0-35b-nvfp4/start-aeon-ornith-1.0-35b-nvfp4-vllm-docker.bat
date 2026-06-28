@echo off
setlocal

rem ============================================================
rem  AEON Ornith 1.0 35B Ultimate Uncensored NVFP4 vLLM launcher.
rem  Blackwell-only compressed-tensors NVFP4 profile.
rem  Serves an OpenAI-compatible endpoint on port 39187.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "REPO_ID=AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4"
set "MODEL_ALIAS=aeon-ornith-1.0-35b-nvfp4"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined MODEL_DIR (
  set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\AEON-7\Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4"
)
if not defined IMAGE set "IMAGE=vllm/vllm-openai:nightly"
set "CONTAINER_NAME=aeon-ornith-35b-nvfp4-vllm"
set "HF_CACHE_VOLUME=aeon-ornith-35b-nvfp4-hf-cache"
if not defined HOST_PORT set "HOST_PORT=39187"
if not defined CONTAINER_PORT set "CONTAINER_PORT=8000"
if not defined MAX_MODEL_LEN set "MAX_MODEL_LEN=262144"
if not defined MAX_NUM_SEQS set "MAX_NUM_SEQS=1"
if not defined MAX_NUM_BATCHED_TOKENS set "MAX_NUM_BATCHED_TOKENS=8192"
if not defined GPU_MEMORY_UTILIZATION set "GPU_MEMORY_UTILIZATION=0.9485"
if not defined MAMBA_CACHE_DTYPE set "MAMBA_CACHE_DTYPE=float32"
if not defined SAFETENSORS_LOAD_STRATEGY set "SAFETENSORS_LOAD_STRATEGY=prefetch"
if not defined VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS set "VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS=0"
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

if defined MODEL_VOLUME (
  set "MODEL_SOURCE=%MODEL_VOLUME%:/model:ro"
  set "MODEL_DISPLAY=docker volume %MODEL_VOLUME%"
) else (
  if not exist "%MODEL_DIR%\config.json" (
    echo.
    echo ERROR: Model snapshot not found at:
    echo   %MODEL_DIR%
    echo.
    echo Download it first with:
    echo   download-aeon-ornith-1.0-35b-nvfp4.bat
    echo.
    pause
    exit /b 1
  )
  set "MODEL_SOURCE=%MODEL_DIR%:/model:ro"
  set "MODEL_DISPLAY=%MODEL_DIR%"
)

if not defined MODEL_SOURCE (
  echo.
  echo ERROR: Model source was not configured.
  echo.
  pause
  exit /b 1
)

echo Starting %MODEL_ALIAS% with vLLM Docker
echo.
echo Desktop base URL:  http://127.0.0.1:%HOST_PORT%/v1
echo LAN base URL:      http://^<your-lan-ip^>:%HOST_PORT%/v1
echo Model id:          %MODEL_ALIAS%
echo Model source:      %MODEL_DISPLAY%
echo Docker image:      %IMAGE%
echo HF cache volume:   %HF_CACHE_VOLUME%
echo Context:           %MAX_MODEL_LEN% tokens
echo Quantization:      compressed-tensors NVFP4
echo Mamba cache dtype: %MAMBA_CACHE_DTYPE%
echo Safetensors load:  %SAFETENSORS_LOAD_STRATEGY%
echo CUDA graph memory: estimate=%VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS%
echo.
echo Close other local GPU model servers first. This profile needs most of the 5090.
echo In Hermes use provider "Local 5090" and model "%MODEL_ALIAS%".
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
  -e VLLM_NVFP4_GEMM_BACKEND=flashinfer-cutlass ^
  -e VLLM_USE_FLASHINFER_SAMPLER=1 ^
  -e VLLM_MEMORY_PROFILER_ESTIMATE_CUDAGRAPHS ^
  -e HF_TOKEN ^
  -v "%MODEL_SOURCE%" ^
  -v "%HF_CACHE_VOLUME%:/root/.cache/huggingface" ^
  --entrypoint vllm ^
  "%IMAGE%" ^
  serve /model ^
  --host 0.0.0.0 ^
  --port %CONTAINER_PORT% ^
  --served-model-name "%MODEL_ALIAS%" ^
  --tensor-parallel-size 1 ^
  --quantization compressed-tensors ^
  --trust-remote-code ^
  --safetensors-load-strategy %SAFETENSORS_LOAD_STRATEGY% ^
  --mamba-cache-dtype %MAMBA_CACHE_DTYPE% ^
  --max-model-len %MAX_MODEL_LEN% ^
  --max-num-seqs %MAX_NUM_SEQS% ^
  --max-num-batched-tokens %MAX_NUM_BATCHED_TOKENS% ^
  --gpu-memory-utilization %GPU_MEMORY_UTILIZATION% ^
  --enable-chunked-prefill ^
  --enable-prefix-caching ^
  --reasoning-parser qwen3 ^
  --tool-call-parser qwen3_coder ^
  --enable-auto-tool-choice

echo.
echo Server exited with code %ERRORLEVEL%.
pause
