@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
set "CHECKOUT_PARENT=%REPO_ROOT%\.."
set "BENCH=%REPO_ROOT%\scripts\benchmarks\bench-llamacpp-nvfp4-mtp-two-point.ps1"
set "MODEL_PATH=%CHECKOUT_PARENT%\.local-model-cache\unsloth\Qwen3.6-27B-NVFP4-MTP-GGUF\qwen3.6-27b-unsloth-nvfp4-mtp-gguf.gguf"

powershell -NoProfile -ExecutionPolicy Bypass -File "%BENCH%" -ModelPath "%MODEL_PATH%" -ModelAlias "qwen36-27b-unsloth-nvfp4-mtp-gguf" -CasePrefix "qwen36-27b-unsloth-nvfp4-mtp-gguf-llamacpp-ctx200k-draft-mtp-mtpn2-request-nothink" -Port 39196
pause
