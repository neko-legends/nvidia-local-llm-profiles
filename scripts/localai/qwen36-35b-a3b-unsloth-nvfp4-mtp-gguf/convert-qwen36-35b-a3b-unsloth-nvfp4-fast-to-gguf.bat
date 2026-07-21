@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined SOURCE_MODEL_DIR set "SOURCE_MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-35B-A3B-NVFP4-Fast"
if not defined OUT_DIR set "OUT_DIR=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-35B-A3B-NVFP4-Fast-MTP-GGUF"
if not defined OUTFILE set "OUTFILE=%OUT_DIR%\qwen3.6-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.gguf"
if not defined LLAMA_CPP_SRC set "LLAMA_CPP_SRC=%CHECKOUT_PARENT%\.llama-runtimes\llama-b10068-src"
set "MIXED_PATCH=%SCRIPT_DIR%..\llama-cpp-mixed-nvfp4-converter.patch"

if not exist "%LLAMA_CPP_SRC%\convert_hf_to_gguf.py" (
  echo ERROR: llama.cpp converter source not found at %LLAMA_CPP_SRC%
  echo Clone llama.cpp b10068 there or set LLAMA_CPP_SRC explicitly.
  exit /b 1
)
if not exist "%SOURCE_MODEL_DIR%\model-00005-of-00005.safetensors" (
  echo ERROR: source snapshot is incomplete. Run the Fast download script first.
  exit /b 1
)
findstr /c:"mixed_nvfp4_compressed_tensors" "%LLAMA_CPP_SRC%\conversion\base.py" >nul
if errorlevel 1 (
  git -C "%LLAMA_CPP_SRC%" apply --check "%MIXED_PATCH%"
  if errorlevel 1 exit /b 1
  git -C "%LLAMA_CPP_SRC%" apply "%MIXED_PATCH%"
  if errorlevel 1 exit /b 1
)
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo Converting: %SOURCE_MODEL_DIR%
echo Writing:    %OUTFILE%
echo Preserving native NVFP4 expert tensors and the bundled MTP block.
py -3.12 "%LLAMA_CPP_SRC%\convert_hf_to_gguf.py" "%SOURCE_MODEL_DIR%" --outfile "%OUTFILE%" --outtype auto --fp8-as-q8 --model-name unsloth-Qwen3.6-35B-A3B-NVFP4-Fast-MTP
if errorlevel 1 goto :failed
if not exist "%OUTFILE%" goto :failed
for %%I in ("%OUTFILE%") do if %%~zI LEQ 0 goto :failed
echo Conversion complete: %OUTFILE%
exit /b 0

:failed
echo ERROR: GGUF conversion failed.
exit /b 1
