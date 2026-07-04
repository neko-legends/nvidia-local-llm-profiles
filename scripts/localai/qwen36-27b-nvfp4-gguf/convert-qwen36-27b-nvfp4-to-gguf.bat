@echo off
setlocal

rem ============================================================
rem  Convert NVIDIA Qwen3.6 27B NVFP4 + MTP to GGUF.
rem
rem  Required:
rem    set LLAMA_CPP_SRC=C:\path\to\llama.cpp
rem
rem  Optional:
rem    set PYTHON_EXE=py
rem    set PYTHON_ARGS=-3.12
rem    set SOURCE_MODEL_DIR=C:\path\to\nvidia\Qwen3.6-27B-NVFP4
rem    set OUTFILE=C:\path\to\qwen3.6-27b-nvfp4-mtp-gguf.gguf
rem ============================================================
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"

if not defined SOURCE_MODEL_DIR set "SOURCE_MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4"
if not defined OUT_DIR set "OUT_DIR=%CHECKOUT_PARENT%\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4-MTP-GGUF"
if not defined OUTFILE set "OUTFILE=%OUT_DIR%\qwen3.6-27b-nvfp4-mtp-gguf.gguf"
if not defined PYTHON_EXE set "PYTHON_EXE=py"
if not defined PYTHON_ARGS set "PYTHON_ARGS=-3.12"

if not defined LLAMA_CPP_SRC (
  echo.
  echo ERROR: LLAMA_CPP_SRC is not set.
  echo.
  echo Set it to a recent llama.cpp source checkout containing convert_hf_to_gguf.py:
  echo   set LLAMA_CPP_SRC=C:\path\to\llama.cpp
  echo.
  pause
  exit /b 1
)

if not exist "%LLAMA_CPP_SRC%\convert_hf_to_gguf.py" (
  echo.
  echo ERROR: convert_hf_to_gguf.py not found at:
  echo   %LLAMA_CPP_SRC%
  echo.
  pause
  exit /b 1
)

if not exist "%SOURCE_MODEL_DIR%\config.json" (
  echo.
  echo ERROR: source model snapshot not found:
  echo   %SOURCE_MODEL_DIR%
  echo.
  echo Download nvidia/Qwen3.6-27B-NVFP4 into that folder first:
  echo   download-qwen36-27b-nvfp4.bat
  echo.
  pause
  exit /b 1
)

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo Converting source:
echo   %SOURCE_MODEL_DIR%
echo.
echo Writing GGUF:
echo   %OUTFILE%
echo.
echo Note: NVIDIA publishes this NVFP4 checkpoint for vLLM/modelopt. The
echo source snapshot includes mtp.* tensors, so this conversion keeps the MTP
echo block in the GGUF by default.
echo.
echo GGUF conversion requires a recent llama.cpp with support for this
echo architecture and quantization metadata.
echo.

"%PYTHON_EXE%" %PYTHON_ARGS% "%LLAMA_CPP_SRC%\convert_hf_to_gguf.py" "%SOURCE_MODEL_DIR%" --outfile "%OUTFILE%" --outtype auto --model-name nvidia-Qwen3.6-27B-NVFP4-MTP

echo.
echo Converter exited with code %ERRORLEVEL%.
pause
