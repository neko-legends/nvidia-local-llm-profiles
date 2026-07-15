@echo off
setlocal
call "%~dp0..\..\hermes\install-local-5090-provider.bat" -Qwen36_27bDflashBaseUrl "http://127.0.0.1:39201/v1" %*
exit /b %ERRORLEVEL%
