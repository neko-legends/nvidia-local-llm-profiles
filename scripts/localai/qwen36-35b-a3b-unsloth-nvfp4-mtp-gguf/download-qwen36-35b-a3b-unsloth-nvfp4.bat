@echo off
setlocal

rem Download Unsloth Qwen3.6 35B A3B NVFP4 source weights.
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "REPO_ID=unsloth/Qwen3.6-35B-A3B-NVFP4"
if not defined MODEL_DIR set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-35B-A3B-NVFP4"

echo Downloading %REPO_ID%
echo Destination: %MODEL_DIR%

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"
py -3.12 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id=r'%REPO_ID%', local_dir=r'%MODEL_DIR%')"
if errorlevel 1 goto :failed

if not exist "%MODEL_DIR%\config.json" goto :missing
if not exist "%MODEL_DIR%\model.safetensors.index.json" goto :missing
echo Download complete. Run convert-qwen36-35b-a3b-unsloth-nvfp4-to-gguf.bat next.
pause
exit /b 0

:missing
echo Download completed but required model files are missing. Check %MODEL_DIR%
:failed
pause
exit /b 1
