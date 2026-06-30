@echo off
setlocal

rem ============================================================
rem  Download Qwopus3.6 35B A3B Coder MTP Q5_K_M GGUF.
rem  Default target:
rem    <checkout-parent>\.local-model-cache\Jackrong\Qwopus3.6-35B-A3B-Coder-MTP-GGUF
rem ============================================================
for %%I in ("%~dp0..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\Jackrong\Qwopus3.6-35B-A3B-Coder-MTP-GGUF"
set "FILENAME=Qwopus3.6-35B-A3B-Coder-MTP-Q5_K_M.gguf"
set "REPO_ID=Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF"

echo ============================================================
echo  Downloading: %REPO_ID%
echo  File:        %FILENAME%
echo  Destination: %MODEL_DIR%\%FILENAME%
echo ============================================================
echo.
echo If auth is needed, run one of:
echo   huggingface-cli login
echo   hf login
echo Or set HF_TOKEN before running this script.
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
echo   start-qwopus3.6-35b-a3b-coder-mtp-q5-k-m-server.bat
echo.
pause
