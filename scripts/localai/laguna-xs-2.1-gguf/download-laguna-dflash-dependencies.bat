@echo off
setlocal
for %%I in ("%~dp0..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "DRAFT_DIR=%CHECKOUT_PARENT%\.local-model-cache\Lucebox\Laguna-XS-2.1-DFlash-GGUF"
set "PREFILL_DIR=%CHECKOUT_PARENT%\.local-model-cache\Qwen\Qwen3-0.6B-GGUF"

echo Downloading the unmodified Lucebox DFlash and Qwen prefill drafter GGUFs...
python -c "from huggingface_hub import hf_hub_download; print(hf_hub_download(repo_id='Lucebox/Laguna-XS-2.1-DFlash-GGUF', filename='laguna-xs21-dflash-q4.gguf', local_dir=r'%DRAFT_DIR%')); print(hf_hub_download(repo_id='Qwen/Qwen3-0.6B-GGUF', filename='Qwen3-0.6B-Q8_0.gguf', local_dir=r'%PREFILL_DIR%'))"
if errorlevel 1 (
  echo Download failed. Install the dependency with: pip install -U huggingface_hub
  exit /b 1
)
echo DFlash dependencies downloaded successfully.

