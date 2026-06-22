param(
    [string]$TargetDir = "D:\Tools\LocalAI"
)

$ErrorActionPreference = "Stop"

$sourceDir = $PSScriptRoot
$targetDirFull = [System.IO.Path]::GetFullPath($TargetDir)

if (-not (Test-Path -LiteralPath $targetDirFull)) {
    New-Item -ItemType Directory -Path $targetDirFull | Out-Null
}

$files = @(
    "start-qwopus3.6-27b-coder-mtp-q5-server.bat",
    "allow-qwopus3.6-coder-mtp-server-firewall-admin.bat",
    "qwopus3.6-27b-coder-mtp-q5-server-notes.md"
)

foreach ($file in $files) {
    $source = Join-Path $sourceDir $file
    $target = Join-Path $targetDirFull $file
    Copy-Item -LiteralPath $source -Destination $target -Force
}

Write-Host ""
Write-Host "Installed Qwopus3.6 Coder MTP launcher files to:" -ForegroundColor Cyan
Write-Host $targetDirFull
Write-Host ""
Write-Host "Next:"
Write-Host "1. Put Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf in D:\Tools\LocalAI\models"
Write-Host "2. Run start-qwopus3.6-27b-coder-mtp-q5-server.bat"
Write-Host "3. If Hermes Client cannot connect remotely, run allow-qwopus3.6-coder-mtp-server-firewall-admin.bat"
Write-Host ""
