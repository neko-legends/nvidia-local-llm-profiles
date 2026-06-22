@echo off
setlocal

set "MODEL_DIR=D:\Tools\LocalAI\models\Qwen3.6-27B-Text-NVFP4-MTP"
set "REPO_ID=sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP"
set "HF_EXE=%APPDATA%\Python\Python311\Scripts\hf.exe"

if not exist "D:\Tools\LocalAI" (
    echo D:\Tools\LocalAI was not found.
    pause
    exit /b 1
)

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

echo Downloading %REPO_ID%
echo Target folder: %MODEL_DIR%
echo.

if exist "%HF_EXE%" (
    "%HF_EXE%" download %REPO_ID% --local-dir "%MODEL_DIR%"
) else (
    python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='%REPO_ID%', local_dir=r'%MODEL_DIR%')"
)

if errorlevel 1 (
    echo.
    echo Download failed.
    echo If Python reported a missing package, install huggingface_hub or use the Hugging Face CLI.
    pause
    exit /b 1
)

echo 262144>"%MODEL_DIR%\.recommended-max-model-len"

echo.
echo Download complete.
echo Model folder:
echo %MODEL_DIR%
pause
