@echo off
setlocal
call "%~dp0start-qwen36-27b-nvfp4-dflash-q8-0-server.bat" %*
exit /b %ERRORLEVEL%
