@echo off
setlocal

rem ============================================================
rem  Download the Unsloth Qwen3.6 35B A3B MTP GGUF.
rem  Default target: models\Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf
rem ============================================================
set "MODEL_DIR=%~dp0models"
set "FILENAME=Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"
set "REPO_ID=unsloth/Qwen3.6-35B-A3B-MTP-GGUF"

echo ============================================================
echo  Downloading: %REPO_ID%
echo  File:        %FILENAME%
echo  Destination: %MODEL_DIR%\%FILENAME%
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
    echo Download failed. If the CLI is missing:
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
echo   start-qwen36-35b-a3b-mtp-ud-q4-k-xl-server.bat
echo.
pause
