@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%..\..\hermes\install-local-5090-provider.bat" -TernaryBonsai27bBaseUrl "http://127.0.0.1:39199/v1" %*
exit /b %ERRORLEVEL%
