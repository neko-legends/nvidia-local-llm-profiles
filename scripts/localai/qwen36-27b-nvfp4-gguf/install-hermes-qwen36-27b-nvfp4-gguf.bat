@echo off
setlocal

rem Installs/refreshes the consolidated Hermes "Local 5090" provider and
rem includes the Qwen3.6 27B NVFP4 GGUF route on port 39195.
set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%..\..\hermes\install-local-5090-provider.bat" -Qwen36_27bNvfp4BaseUrl "http://127.0.0.1:39195/v1" %*
exit /b %ERRORLEVEL%
