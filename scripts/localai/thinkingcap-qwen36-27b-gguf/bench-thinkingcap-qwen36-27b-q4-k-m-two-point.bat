@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
set "CHECKOUT_PARENT=%REPO_ROOT%\.."
set "BENCH=%REPO_ROOT%\scripts\benchmarks\bench-llamacpp-nvfp4-mtp-two-point.ps1"
set "MODEL_PATH=%CHECKOUT_PARENT%\.local-model-cache\bottlecapai\ThinkingCap-Qwen3.6-27B-GGUF\ThinkingCap-Qwen3.6-27B-Q4_K_M.gguf"

powershell -NoProfile -ExecutionPolicy Bypass -File "%BENCH%" -ModelPath "%MODEL_PATH%" -ModelAlias "thinkingcap-qwen36-27b-q4-k-m" -CasePrefix "thinkingcap-qwen36-27b-q4-k-m-llamacpp-ctx200k-draft-mtp-mtpn4-request-nothink" -Port 39198 -SpecDraftNMax 4
pause
