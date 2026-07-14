@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%..\..\hermes\install-local-5090-provider.bat" -ThinkingCapQwen36_27bBaseUrl "http://127.0.0.1:39198/v1" %*
exit /b %ERRORLEVEL%
