@echo off
setlocal

set "RULE_NAME=AEON Ornith NVFP4 vLLM server 39187"
set "LOCAL_PORT=39187"

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
  echo Requesting administrator permission to add the firewall rule...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ruleName = '%RULE_NAME%';" ^
  "$port = %LOCAL_PORT%;" ^
  "Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule;" ^
  "New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -Profile Any | Out-Host"

echo.
echo Firewall rule installed for TCP %LOCAL_PORT%.
pause
