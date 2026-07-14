@echo off
setlocal EnableDelayedExpansion

rem Native Windows llama.cpp launcher for ThinkingCap Qwen3.6 27B Q4_K_M.
rem The upstream GGUF includes an MTP draft head; no separate draft model is needed.
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "MODEL_CACHE_DIR=%CHECKOUT_PARENT%\.local-model-cache\bottlecapai\ThinkingCap-Qwen3.6-27B-GGUF"
if not defined MODEL_PATH set "MODEL_PATH=%MODEL_CACHE_DIR%\ThinkingCap-Qwen3.6-27B-Q4_K_M.gguf"
set "MODEL_ALIAS=thinkingcap-qwen36-27b-q4-k-m"
set "HOST=0.0.0.0"
set "PORT=39198"
set "CTX_SIZE=200000"
set "THINKING=0"
if not defined SPEC_DRAFT_N_MAX set "SPEC_DRAFT_N_MAX=4"

set "LLAMA_SERVER="
if defined LLAMA_DIR if exist "%LLAMA_DIR%\llama-server.exe" set "LLAMA_SERVER=%LLAMA_DIR%\llama-server.exe"
if not defined LLAMA_SERVER for /f "usebackq delims=" %%F in (`where llama-server.exe 2^>nul`) do if not defined LLAMA_SERVER set "LLAMA_SERVER=%%F"
if not defined LLAMA_SERVER (
  echo ERROR: llama-server.exe was not found. Set LLAMA_DIR to a recent CUDA llama.cpp build.
  pause
  exit /b 1
)
if not exist "%MODEL_PATH%" (
  echo ERROR: Model file not found:
  echo   %MODEL_PATH%
  echo Run download-thinkingcap-qwen36-27b-q4-k-m.bat first.
  pause
  exit /b 1
)

for %%I in ("%LLAMA_SERVER%") do set "LLAMA_DIR=%%~dpI"
set "REASONING_FLAG=--reasoning off"
if "%THINKING%"=="1" set "REASONING_FLAG=--reasoning on"

echo Model:   %MODEL_ALIAS%
echo URL:     http://127.0.0.1:%PORT%/v1
echo Context: %CTX_SIZE%  MTP: draft-mtp n=%SPEC_DRAFT_N_MAX%  Thinking: %THINKING%
cd /d "%LLAMA_DIR%"
"%LLAMA_SERVER%" --model "%MODEL_PATH%" --alias "%MODEL_ALIAS%" --host %HOST% --port %PORT% --device CUDA0 --gpu-layers all --gpu-layers-draft all --ctx-size %CTX_SIZE% --cache-type-k q4_0 --cache-type-v q4_0 --cache-type-k-draft q4_0 --cache-type-v-draft q4_0 --flash-attn on --parallel 1 --cont-batching --jinja --metrics --slots %REASONING_FLAG% --spec-type draft-mtp --spec-draft-n-max %SPEC_DRAFT_N_MAX% --spec-draft-p-min 0.0
pause
