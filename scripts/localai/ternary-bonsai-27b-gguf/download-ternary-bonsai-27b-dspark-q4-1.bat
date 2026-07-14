@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "CHECKOUT_PARENT=%%~fI"
set "REPO_ID=prism-ml/Ternary-Bonsai-27B-gguf"
if not defined MODEL_DIR set "MODEL_DIR=%CHECKOUT_PARENT%\.local-model-cache\prism-ml\Ternary-Bonsai-27B-gguf"
set "TARGET_FILE=Ternary-Bonsai-27B-Q2_0.gguf"
set "DRAFT_FILE=Ternary-Bonsai-27B-dspark-Q4_1.gguf"

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"
echo Downloading the Ternary-Bonsai target and recommended DSpark drafter...
echo Destination: %MODEL_DIR%

where hf >nul 2>&1
if %ERRORLEVEL% == 0 (
  hf download "%REPO_ID%" "%TARGET_FILE%" "%DRAFT_FILE%" --local-dir "%MODEL_DIR%"
  goto :check
)
where huggingface-cli >nul 2>&1
if %ERRORLEVEL% == 0 (
  huggingface-cli download "%REPO_ID%" "%TARGET_FILE%" "%DRAFT_FILE%" --local-dir "%MODEL_DIR%"
  goto :check
)
py -3.12 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id=r'%REPO_ID%', allow_patterns=[r'%TARGET_FILE%',r'%DRAFT_FILE%'], local_dir=r'%MODEL_DIR%')"

:check
if errorlevel 1 goto :failed
for %%F in ("%MODEL_DIR%\%TARGET_FILE%" "%MODEL_DIR%\%DRAFT_FILE%") do if not exist "%%~F" goto :missing
for %%F in ("%MODEL_DIR%\%TARGET_FILE%" "%MODEL_DIR%\%DRAFT_FILE%") do if %%~zF LEQ 0 goto :missing
echo.
echo Download complete. The Q4_1 file is the speculative drafter; the Q2_0 file is the target model.
exit /b 0

:missing
echo ERROR: A downloaded GGUF is missing or empty in %MODEL_DIR%.
:failed
exit /b 1
