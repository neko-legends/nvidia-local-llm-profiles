@echo off
setlocal
for %%I in ("%~dp0..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "REPO_ID=nvidia/Qwen3.6-35B-A3B-NVFP4"
if not defined MODEL_DIR set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\nvidia\Qwen3.6-35B-A3B-NVFP4"

echo Downloading %REPO_ID% to %MODEL_DIR%...
where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
  hf download "%REPO_ID%" --local-dir "%MODEL_DIR%"
  goto :check
)
where huggingface-cli >nul 2>&1
if %ERRORLEVEL% == 0 (
  huggingface-cli download "%REPO_ID%" --local-dir "%MODEL_DIR%"
  goto :check
)
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id=r'%REPO_ID%', local_dir=r'%MODEL_DIR%')"

:check
if errorlevel 1 (
  echo Download failed. Install the dependency with: pip install -U "huggingface_hub[cli]"
  exit /b 1
)
echo Download complete.
