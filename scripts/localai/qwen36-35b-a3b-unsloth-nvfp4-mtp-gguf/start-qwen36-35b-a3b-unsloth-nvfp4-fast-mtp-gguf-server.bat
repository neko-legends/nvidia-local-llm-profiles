@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined LLAMA_DIR set "LLAMA_DIR=%CHECKOUT_PARENT%\.llama-runtimes\llama-b10068-bin-win-cuda-13.3-x64"
if not defined MODEL_PATH set "MODEL_PATH=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-35B-A3B-NVFP4-Fast-MTP-GGUF\qwen3.6-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.gguf"
set "MODEL_ALIAS=qwen36-35b-a3b-unsloth-nvfp4-fast-mtp-gguf"
set "PORT=39202"
if not defined CTX_SIZE set "CTX_SIZE=200000"
if not defined SPEC_DRAFT_N_MAX set "SPEC_DRAFT_N_MAX=2"

if not exist "%LLAMA_DIR%\llama-server.exe" (
  echo ERROR: llama.cpp b10068 runtime not found. Run install-llama-b10068-win-cuda13.bat first.
  exit /b 1
)
if not exist "%MODEL_PATH%" (
  echo ERROR: model not found: %MODEL_PATH%
  exit /b 1
)
echo Model:   %MODEL_ALIAS%
echo URL:     http://127.0.0.1:%PORT%/v1
echo Context: %CTX_SIZE%  MTP: n=%SPEC_DRAFT_N_MAX%  Thinking: off
cd /d "%LLAMA_DIR%"
"%LLAMA_DIR%\llama-server.exe" --model "%MODEL_PATH%" --alias "%MODEL_ALIAS%" --host 0.0.0.0 --port %PORT% --device CUDA0 --gpu-layers all --gpu-layers-draft all --ctx-size %CTX_SIZE% --cache-type-k q4_0 --cache-type-v q4_0 --cache-type-k-draft q4_0 --cache-type-v-draft q4_0 --flash-attn on --parallel 1 --cont-batching --jinja --metrics --slots --reasoning off --spec-type draft-mtp --spec-draft-n-max %SPEC_DRAFT_N_MAX% --spec-draft-p-min 0.0
exit /b %ERRORLEVEL%
