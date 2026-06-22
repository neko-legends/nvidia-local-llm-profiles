@echo off
setlocal

rem ============================================================
rem  CONFIGURE: MODEL_DIR is where the model folder will be saved.
rem  Default: models\Qwen3.6-27B-Text-NVFP4-MTP relative to this script.
rem  This script is a copy of download-qwen3.6-27B-Text-NVFP4-MTP.bat
rem  installed alongside the launcher. They do the same thing.
rem ============================================================
set "MODEL_DIR=%~dp0models\Qwen3.6-27B-Text-NVFP4-MTP"
set "REPO_ID=sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"

echo ============================================================
echo  Downloading: %REPO_ID%
echo  Destination: %MODEL_DIR%
echo ============================================================
echo.
echo NOTE: A free Hugging Face account may be required to download
echo this model. If the download fails with a 401 or auth error:
echo.
echo   1. Create a free account at https://huggingface.co
echo   2. Visit the model page and accept any license agreement:
echo      https://huggingface.co/%REPO_ID%
echo   3. Log in on this machine with one of:
echo        huggingface-cli login
echo        hf login
echo      Or set the HF_TOKEN environment variable to your token.
echo      (Generate a token at https://huggingface.co/settings/tokens)
echo.
echo ============================================================
echo.

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

rem Try huggingface-cli from PATH first
where huggingface-cli >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using huggingface-cli ...
    huggingface-cli download %REPO_ID% --local-dir "%MODEL_DIR%"
    goto :check
)

rem Try hf CLI from PATH
where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using hf CLI ...
    hf download %REPO_ID% --local-dir "%MODEL_DIR%"
    goto :check
)

rem Fall back to Python huggingface_hub
echo huggingface-cli / hf not found in PATH. Trying Python huggingface_hub ...
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='%REPO_ID%', local_dir=r'%MODEL_DIR%')"

:check
if errorlevel 1 (
    echo.
    echo Download failed. Check the error above.
    echo.
    echo If you see a 401 or authentication error, log in first:
    echo   huggingface-cli login
    echo.
    echo If huggingface_hub or the CLI is not installed:
    echo   pip install -U "huggingface_hub[cli]"
    echo.
    pause
    exit /b 1
)

echo 262144>"%MODEL_DIR%\.recommended-max-model-len"

echo.
echo Download complete.
echo Model saved to:
echo   %MODEL_DIR%
echo.
echo Start the server with:
echo   start-qwen3.6-27B-Text-NVFP4-MTP-server.bat
echo.
pause
