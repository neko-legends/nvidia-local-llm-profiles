@echo off
setlocal

rem Adds current mixed compressed-tensors NVFP4 conversion support to llama.cpp.
rem Run once only when your chosen llama.cpp source still rejects mixed groups.
set "SCRIPT_DIR=%~dp0"
set "PATCH_FILE=%SCRIPT_DIR%llama-cpp-mixed-nvfp4-converter.patch"

if not defined LLAMA_CPP_SRC (
  echo ERROR: LLAMA_CPP_SRC must point to your llama.cpp source checkout.
  echo Example: set LLAMA_CPP_SRC=C:\path\to\llama.cpp
  pause
  exit /b 1
)
if not exist "%LLAMA_CPP_SRC%\convert_hf_to_gguf.py" (
  echo ERROR: convert_hf_to_gguf.py was not found in %LLAMA_CPP_SRC%
  pause
  exit /b 1
)
if not exist "%PATCH_FILE%" (
  echo ERROR: patch file not found: %PATCH_FILE%
  pause
  exit /b 1
)

git -C "%LLAMA_CPP_SRC%" apply --check "%PATCH_FILE%"
if errorlevel 1 (
  echo.
  echo The patch did not apply cleanly. Your llama.cpp may already include this
  echo support, or its converter source has changed. Do not force it blindly.
  pause
  exit /b 1
)

git -C "%LLAMA_CPP_SRC%" apply "%PATCH_FILE%"
if errorlevel 1 (
  echo Patch failed.
  pause
  exit /b 1
)

echo Mixed NVFP4 converter support was applied to:
echo   %LLAMA_CPP_SRC%
pause
