@echo off
setlocal

rem ============================================================
rem  Download AEON Ornith 1.0 35B Ultimate Uncensored NVFP4.
rem  Default target:
rem    <checkout-parent>\.local-model-cache\AEON-7\Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "REPO_ID=AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
if not defined MODEL_DIR (
  set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\AEON-7\Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4"
)

echo ============================================================
echo  Downloading: %REPO_ID%
echo  Destination: %MODEL_DIR%
echo ============================================================
echo.
echo NOTE: This is a large safetensors/compressed-tensors NVFP4 repo.
echo If auth is needed, run one of:
echo   huggingface-cli login
echo   hf login
echo.
echo Model page:
echo   https://huggingface.co/%REPO_ID%
echo.

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

where huggingface-cli >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using huggingface-cli ...
    huggingface-cli download %REPO_ID% --local-dir "%MODEL_DIR%"
    goto :check
)

where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using hf CLI ...
    hf download %REPO_ID% --local-dir "%MODEL_DIR%"
    goto :check
)

echo huggingface-cli / hf not found in PATH. Trying Python huggingface_hub ...
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='%REPO_ID%', local_dir=r'%MODEL_DIR%')"

:check
if errorlevel 1 (
    echo.
    echo Download failed. If the Hugging Face CLI is missing:
    echo   pip install -U "huggingface_hub[cli]"
    echo.
    echo If auth is required:
    echo   huggingface-cli login
    echo.
    pause
    exit /b 1
)

echo.
echo Download complete.
echo Model snapshot saved to:
echo   %MODEL_DIR%
echo.
echo Start the vLLM server with:
echo   start-aeon-ornith-1.0-35b-nvfp4-vllm-docker.bat
echo.
pause
