@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined LLAMA_DIR set "LLAMA_DIR=%CHECKOUT_PARENT%\.llama-runtimes\buun-dflash-34501c5-sm120-win-cuda13.3"
if not defined TARGET_MODEL set "TARGET_MODEL=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-27B-GGUF\Qwen3.6-27B-Q4_K_M.gguf"
if not defined DRAFT_MODEL set "DRAFT_MODEL=%CHECKOUT_PARENT%\.local-model-cache\spiritbuun\Qwen3.6-27B-DFlash-GGUF\dflash-draft-3.6-q8_0.gguf"
if not defined PORT set "PORT=39201"
if not defined CTX_SIZE set "CTX_SIZE=200000"
set "MODEL_ALIAS=qwen36-27b-q4-k-m-dflash-q8-0"

if not exist "%LLAMA_DIR%\llama-server.exe" (
  echo ERROR: DFlash llama-server runtime not found. Run build-buun-dflash-sm120-runtime.bat first.
  exit /b 1
)
if not exist "%TARGET_MODEL%" (
  echo ERROR: Target GGUF not found: %TARGET_MODEL%
  exit /b 1
)
if not exist "%DRAFT_MODEL%" (
  echo ERROR: DFlash draft GGUF not found. Run download-qwen36-27b-dflash-q8-0.bat first.
  exit /b 1
)

echo Starting %MODEL_ALIAS% at http://127.0.0.1:%PORT%/v1
echo Target context: %CTX_SIZE%; draft context: 256
cd /d "%LLAMA_DIR%"
"%LLAMA_DIR%\llama-server.exe" ^
  --model "%TARGET_MODEL%" ^
  --model-draft "%DRAFT_MODEL%" ^
  --alias "%MODEL_ALIAS%" ^
  --host 0.0.0.0 --port %PORT% ^
  --device CUDA0 --device-draft CUDA0 ^
  --gpu-layers all --gpu-layers-draft all ^
  --ctx-size %CTX_SIZE% ^
  --cache-type-k q4_0 --cache-type-v q4_0 ^
  --cache-type-k-draft q4_0 --cache-type-v-draft q4_0 ^
  --flash-attn on --parallel 1 --cont-batching ^
  --batch-size 8192 --ubatch-size 2048 ^
  --spec-dflash-default ^
  --jinja --chat-template-kwargs "{\"enable_thinking\":false}" --reasoning off ^
  --metrics --slots -lv 4
