param(
    # TargetDir: where the launcher scripts are copied.
    # Default: an "installed" folder next to this script.
    # Override to install somewhere else, e.g.:
    #   .\install-to-LocalAI.ps1 -TargetDir "C:\LocalAI"
    [string]$TargetDir = "$PSScriptRoot\..\installed"
)

$ErrorActionPreference = "Stop"

$sourceDir = $PSScriptRoot
$targetDirFull = [System.IO.Path]::GetFullPath($TargetDir)

if (-not (Test-Path -LiteralPath $targetDirFull)) {
    New-Item -ItemType Directory -Path $targetDirFull | Out-Null
}

# Create a models subfolder if it doesn't exist
$modelsDir = Join-Path $targetDirFull "models"
if (-not (Test-Path -LiteralPath $modelsDir)) {
    New-Item -ItemType Directory -Path $modelsDir | Out-Null
}

$files = @(
    "start-qwopus3.6-27b-coder-mtp-q5-server.bat",
    "download-qwopus3.6-27B-Coder-MTP-Q5.bat",
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
Write-Host "Next steps:"
Write-Host "1. Edit LLAMA_DIR in start-qwopus3.6-27b-coder-mtp-q5-server.bat to point at your llama.cpp CUDA build."
Write-Host "   Download llama.cpp CUDA releases from: https://github.com/ggml-org/llama.cpp/releases"
Write-Host "2. Run download-qwopus3.6-27B-Coder-MTP-Q5.bat to download the model (free HF account may be required)."
Write-Host "3. Run start-qwopus3.6-27b-coder-mtp-q5-server.bat to start the server."
Write-Host "4. If Hermes Client cannot connect remotely, run allow-qwopus3.6-coder-mtp-server-firewall-admin.bat as admin."
Write-Host ""
