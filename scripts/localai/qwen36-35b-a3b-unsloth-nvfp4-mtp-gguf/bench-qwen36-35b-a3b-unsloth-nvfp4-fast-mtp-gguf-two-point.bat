@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
if not defined LLAMA_DIR set "LLAMA_DIR=%CHECKOUT_PARENT%\.llama-runtimes\llama-b10068-bin-win-cuda-13.3-x64"
set "MODEL_PATH=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-35B-A3B-NVFP4-Fast-MTP-GGUF\qwen3.6-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.gguf"
set "BENCH=%REPO_ROOT%\scripts\benchmarks\bench-llamacpp-nvfp4-mtp-two-point.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%BENCH%" -LlamaDir "%LLAMA_DIR%" -ModelPath "%MODEL_PATH%" -ModelAlias "qwen36-35b-a3b-unsloth-nvfp4-fast-mtp-gguf" -CasePrefix "qwen36-35b-a3b-unsloth-nvfp4-fast-mtp-gguf-llamacpp-b10068-ctx200k-draft-mtp-mtpn2-request-nothink" -Port 39202
exit /b %ERRORLEVEL%
