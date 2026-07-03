@echo off
setlocal

rem ============================================================
rem  Download NVIDIA Qwen3.6 27B NVFP4 safetensors snapshot.
rem  Default target:
rem    <checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4
rem ============================================================
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"

set "REPO_ID=nvidia/Qwen3.6-27B-NVFP4"
if not defined MODEL_DIR set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4"

echo ============================================================
echo  Downloading: %REPO_ID%
echo  Destination: %MODEL_DIR%
echo ============================================================
echo.
echo If auth is needed, run one of:
echo   huggingface-cli login
echo   hf login
echo.

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

where huggingface-cli >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using huggingface-cli ...
    huggingface-cli download "%REPO_ID%" --local-dir "%MODEL_DIR%"
    goto :check
)

where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using hf CLI ...
    hf download "%REPO_ID%" --local-dir "%MODEL_DIR%"
    goto :check
)

echo huggingface-cli / hf not found in PATH. Trying Python huggingface_hub ...
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id=r'%REPO_ID%', local_dir=r'%MODEL_DIR%')"

:check
if errorlevel 1 (
    echo.
    echo Download failed. If the CLI is missing:
    echo   pip install -U "huggingface_hub[cli]"
    echo.
    pause
    exit /b 1
)

if not exist "%MODEL_DIR%\config.json" (
    echo.
    echo WARNING: config.json was not found after download:
    echo   %MODEL_DIR%\config.json
    echo Check the download output before converting.
    echo.
)

echo.
echo Download complete.
echo Source snapshot saved to:
echo   %MODEL_DIR%
echo.
echo Convert to GGUF with:
echo   convert-qwen36-27b-nvfp4-to-gguf.bat
echo.
pause
