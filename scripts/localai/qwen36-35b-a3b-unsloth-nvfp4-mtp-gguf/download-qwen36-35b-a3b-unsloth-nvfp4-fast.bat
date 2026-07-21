@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "REPO_ID=unsloth/Qwen3.6-35B-A3B-NVFP4-Fast"
if not defined MODEL_DIR set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-35B-A3B-NVFP4-Fast"

echo Downloading %REPO_ID%
echo Destination: %MODEL_DIR%
if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"
py -3.12 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id=r'%REPO_ID%', local_dir=r'%MODEL_DIR%')"
if errorlevel 1 goto :failed
if not exist "%MODEL_DIR%\config.json" goto :failed
if not exist "%MODEL_DIR%\model.safetensors.index.json" goto :failed
if not exist "%MODEL_DIR%\model-00005-of-00005.safetensors" goto :failed
echo Download complete: %MODEL_DIR%
exit /b 0

:failed
echo ERROR: Unsloth Qwen3.6 35B A3B NVFP4 Fast download failed.
exit /b 1
