@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%..\..\hermes\install-local-5090-provider.bat" -UnslothQwen36_27bNvfp4BaseUrl "http://127.0.0.1:39196/v1" %*
exit /b %ERRORLEVEL%
