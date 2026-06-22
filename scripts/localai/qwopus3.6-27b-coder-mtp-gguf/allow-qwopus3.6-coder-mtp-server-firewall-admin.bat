@echo off
setlocal

set "RULE_NAME=LocalAI Qwopus Coder MTP llama.cpp server 39182"
set "LLAMA_EXE=D:\Tools\llama.cpp-b9267-cuda13.1\llama-server.exe"
set "LOCAL_PORT=39182"

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo Requesting administrator permission to add the firewall rule...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ruleName = '%RULE_NAME%';" ^
  "$exe = '%LLAMA_EXE%';" ^
  "$port = %LOCAL_PORT%;" ^
  "Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule;" ^
  "New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -Program $exe -Profile Any | Out-Host"

echo.
echo Firewall rule installed for TCP %LOCAL_PORT%.
pause
