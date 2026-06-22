@echo off
setlocal

rem ============================================================
rem  CONFIGURE: MODEL_DIR is where the .gguf file will be saved.
rem  Default: models\ subfolder relative to this script's location.
rem  If this script was installed via install-to-LocalAI.bat, that
rem  puts the model alongside the launcher in your LocalAI folder.
rem  Edit MODEL_DIR below to use a different location.
rem ============================================================
set "MODEL_DIR=%~dp0models"
set "FILENAME=Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf"
set "REPO_ID=Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF"

echo ============================================================
echo  Downloading: %REPO_ID%
echo  File:        %FILENAME%
echo  Destination: %MODEL_DIR%\%FILENAME%
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
    huggingface-cli download %REPO_ID% %FILENAME% --local-dir "%MODEL_DIR%"
    goto :check
)

rem Try hf CLI from PATH
where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using hf CLI ...
    hf download %REPO_ID% %FILENAME% --local-dir "%MODEL_DIR%"
    goto :check
)

rem Fall back to Python huggingface_hub
echo huggingface-cli / hf not found in PATH. Trying Python huggingface_hub ...
python -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='%REPO_ID%', filename='%FILENAME%', local_dir=r'%MODEL_DIR%')"

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

echo.
echo Download complete.
echo Model saved to:
echo   %MODEL_DIR%\%FILENAME%
echo.
echo Start the server with:
echo   start-qwopus3.6-27b-coder-mtp-q5-server.bat
echo.
pause
