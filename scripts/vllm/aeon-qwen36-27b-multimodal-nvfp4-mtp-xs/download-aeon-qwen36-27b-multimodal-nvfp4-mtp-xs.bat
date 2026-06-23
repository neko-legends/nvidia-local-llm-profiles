@echo off
setlocal

rem ============================================================
rem  Download the full Hugging Face model snapshot for vLLM.
rem  This is a safetensors/modelopt NVFP4 repo, not a GGUF file.
rem ============================================================
set "SCRIPT_DIR=%~dp0"
set "REPO_ID=AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP-XS"
set "MODEL_DIR=%SCRIPT_DIR%models\aeon-ultimate-multimodal-nvfp4-mtp-xs"

echo ============================================================
echo  Downloading: %REPO_ID%
echo  Destination: %MODEL_DIR%
echo ============================================================
echo.
echo NOTE: This is a large safetensors repo. A Hugging Face account
echo or HF_TOKEN may be required if the model page requires auth.
echo.
echo   huggingface-cli login
echo   hf login
echo.
echo Model page:
echo   https://huggingface.co/%REPO_ID%
echo.
echo ============================================================
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
echo   start-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-docker.bat
echo.
pause
