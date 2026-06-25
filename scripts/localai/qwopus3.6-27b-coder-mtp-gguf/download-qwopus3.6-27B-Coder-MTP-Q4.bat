@echo off
setlocal

rem ============================================================
rem  Download Qwopus3.6 27B Coder MTP Q4_K_M GGUF.
rem
rem  Default destination matches the shared local model cache used
rem  by this repo, next to the Q5_K_M variant:
rem    D:\forPublic\.local-model-cache\Jackrong\Qwopus3.6-27B-Coder-MTP-GGUF
rem
rem  Edit MODEL_DIR below if you want a different location.
rem ============================================================
for %%I in ("%~dp0..\..\..\..\.local-model-cache\Jackrong\Qwopus3.6-27B-Coder-MTP-GGUF") do set "MODEL_DIR=%%~fI"
set "FILENAME=Qwopus3.6-27B-Coder-MTP-Q4_K_M.gguf"
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
echo   1. Visit https://huggingface.co/%REPO_ID%
echo   2. Accept any license agreement if prompted
echo   3. Log in with one of:
echo        huggingface-cli login
echo        hf login
echo      Or set HF_TOKEN to your Hugging Face token.
echo.
echo ============================================================
echo.

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

where huggingface-cli >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using huggingface-cli ...
    huggingface-cli download %REPO_ID% %FILENAME% --local-dir "%MODEL_DIR%"
    goto :check
)

where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using hf CLI ...
    hf download %REPO_ID% %FILENAME% --local-dir "%MODEL_DIR%"
    goto :check
)

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
echo Start the Q4 server with:
echo   start-qwopus3.6-27b-coder-mtp-q4-server.bat
echo.
pause
