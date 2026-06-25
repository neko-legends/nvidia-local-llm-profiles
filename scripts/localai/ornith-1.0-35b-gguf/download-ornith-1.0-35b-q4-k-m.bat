@echo off
setlocal

rem ============================================================
rem  Download DeepReinforce Ornith 1.0 35B GGUF Q4_K_M.
rem  Default target:
rem    D:\forPublic\.local-model-cache\deepreinforce-ai\Ornith-1.0-35B-GGUF\ornith-1.0-35b-Q4_K_M.gguf
rem ============================================================
set "MODEL_DIR=D:\forPublic\.local-model-cache\deepreinforce-ai\Ornith-1.0-35B-GGUF"
set "FILENAME=ornith-1.0-35b-Q4_K_M.gguf"
set "REPO_ID=deepreinforce-ai/Ornith-1.0-35B-GGUF"

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
echo   start-ornith-1.0-35b-q4-k-m-server.bat
echo.
pause
