@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "REPO_ID=unsloth/Qwen3.6-27B-GGUF"
set "MODEL_FILE=Qwen3.6-27B-Q4_K_M.gguf"
if not defined MODEL_DIR set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-27B-GGUF"

echo Downloading %REPO_ID%/%MODEL_FILE%
echo Destination: %MODEL_DIR%
if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"
where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
  hf download "%REPO_ID%" "%MODEL_FILE%" --local-dir "%MODEL_DIR%"
  goto :check
)
where huggingface-cli >nul 2>&1
if %ERRORLEVEL% == 0 (
  huggingface-cli download "%REPO_ID%" "%MODEL_FILE%" --local-dir "%MODEL_DIR%"
  goto :check
)
py -3.12 -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id=r'%REPO_ID%', filename=r'%MODEL_FILE%', local_dir=r'%MODEL_DIR%')"

:check
if errorlevel 1 goto :failed
if not exist "%MODEL_DIR%\%MODEL_FILE%" goto :failed
for %%I in ("%MODEL_DIR%\%MODEL_FILE%") do if %%~zI LEQ 0 goto :failed
echo Download complete: %MODEL_DIR%\%MODEL_FILE%
exit /b 0
:failed
echo ERROR: Qwen3.6 27B target download failed.
exit /b 1
