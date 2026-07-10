@echo off
setlocal

rem Convert Unsloth Qwen3.6 27B NVFP4, including its bundled MTP block, to GGUF.
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined SOURCE_MODEL_DIR set "SOURCE_MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-27B-NVFP4"
if not defined OUT_DIR set "OUT_DIR=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-27B-NVFP4-MTP-GGUF"
if not defined OUTFILE set "OUTFILE=%OUT_DIR%\qwen3.6-27b-unsloth-nvfp4-mtp-gguf.gguf"
if not defined PYTHON_EXE set "PYTHON_EXE=py"
if not defined PYTHON_ARGS set "PYTHON_ARGS=-3.12"

if not defined LLAMA_CPP_SRC (
  echo ERROR: LLAMA_CPP_SRC must point to a recent llama.cpp source checkout.
  echo Example: set LLAMA_CPP_SRC=C:\path\to\llama.cpp
  pause
  exit /b 1
)
if not exist "%LLAMA_CPP_SRC%\convert_hf_to_gguf.py" (
  echo ERROR: convert_hf_to_gguf.py was not found in %LLAMA_CPP_SRC%
  pause
  exit /b 1
)
if not exist "%SOURCE_MODEL_DIR%\model.safetensors.index.json" (
  echo ERROR: source snapshot not found. Run download-qwen36-27b-unsloth-nvfp4.bat first.
  pause
  exit /b 1
)
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo Converting: %SOURCE_MODEL_DIR%
echo Writing:    %OUTFILE%
echo The Unsloth checkpoint includes MTP and the conversion keeps it enabled.
echo FP8 weights are stored as Q8_0 so the native GGUF fits practical KV cache.
echo If your llama.cpp reports mixed config groups, run once:
echo   scripts\localai\apply-llama-cpp-mixed-nvfp4-converter-patch.bat
"%PYTHON_EXE%" %PYTHON_ARGS% "%LLAMA_CPP_SRC%\convert_hf_to_gguf.py" "%SOURCE_MODEL_DIR%" --outfile "%OUTFILE%" --outtype auto --fp8-as-q8 --model-name unsloth-Qwen3.6-27B-NVFP4-MTP
echo Converter exited with code %ERRORLEVEL%.
pause
