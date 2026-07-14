@echo off
setlocal
set "USE_DSPARK=0"
set "CTX_SIZE=262144"
call "%~dp0start-ternary-bonsai-27b-dspark-q4-1-server.bat"
exit /b %ERRORLEVEL%
