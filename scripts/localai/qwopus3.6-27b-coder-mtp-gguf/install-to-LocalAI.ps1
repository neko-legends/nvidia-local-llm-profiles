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
    "start-qwopus3.6-27b-coder-mtp-q4-server.bat",
    "download-qwopus3.6-27B-Coder-MTP-Q5.bat",
    "download-qwopus3.6-27B-Coder-MTP-Q4.bat",
    "bench-qwopus3.6-27b-coder-mtp-q4-two-point.bat",
    "bench-with-server-qwopus3.6-27b-coder-mtp-q4.ps1",
    "allow-qwopus3.6-coder-mtp-server-firewall-admin.bat",
    "qwopus3.6-27b-coder-mtp-q5-server-notes.md",
    "qwopus3.6-27b-coder-mtp-q4-server-notes.md"
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
Write-Host "1. Edit LLAMA_DIR in the Q4/Q5 start script to point at your llama.cpp CUDA build."
Write-Host "   Download llama.cpp CUDA releases from: https://github.com/ggml-org/llama.cpp/releases"
Write-Host "2. Run download-qwopus3.6-27B-Coder-MTP-Q5.bat for Q5_K_M, or download-qwopus3.6-27B-Coder-MTP-Q4.bat for Q4_K_M."
Write-Host "3. Run start-qwopus3.6-27b-coder-mtp-q5-server.bat or start-qwopus3.6-27b-coder-mtp-q4-server.bat."
Write-Host "4. Optional: run bench-qwopus3.6-27b-coder-mtp-q4-two-point.bat for the 10k/200k smoke benchmark."
Write-Host "5. If Hermes Client cannot connect remotely, run allow-qwopus3.6-coder-mtp-server-firewall-admin.bat as admin."
Write-Host ""
