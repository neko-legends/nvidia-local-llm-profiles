@echo off
setlocal
for %%I in ("%~dp0..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\poolside\Laguna-XS-2.1-GGUF"
python -c "from huggingface_hub import hf_hub_download; [print(hf_hub_download(repo_id='poolside/Laguna-XS-2.1-GGUF', filename=f, revision='1a37c0a5fb8c7a18e6106decb6be6327d1b63fa6', local_dir=r'%MODEL_DIR%')) for f in ('Laguna-XS-2.1-Q4_K_M.gguf','LICENSE.md','README.md')]"
exit /b %errorlevel%
