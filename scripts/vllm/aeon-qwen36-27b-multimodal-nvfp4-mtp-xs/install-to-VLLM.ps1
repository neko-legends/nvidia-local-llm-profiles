param(
    # TargetDir: where the launcher scripts are copied.
    # Default: an "installed" folder next to this script.
    [string]$TargetDir = "$PSScriptRoot\..\installed-aeon-vllm"
)

$ErrorActionPreference = "Stop"

$sourceDir = $PSScriptRoot
$targetDirFull = [System.IO.Path]::GetFullPath($TargetDir)

if (-not (Test-Path -LiteralPath $targetDirFull)) {
    New-Item -ItemType Directory -Path $targetDirFull | Out-Null
}

$modelsDir = Join-Path $targetDirFull "models"
if (-not (Test-Path -LiteralPath $modelsDir)) {
    New-Item -ItemType Directory -Path $modelsDir | Out-Null
}

$files = @(
    "download-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.bat",
    "start-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-docker.bat",
    "bench-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-context-ladder.bat",
    "allow-aeon-qwen36-vllm-firewall-admin.bat",
    "aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-notes.md"
)

foreach ($file in $files) {
    $source = Join-Path $sourceDir $file
    $target = Join-Path $targetDirFull $file
    Copy-Item -LiteralPath $source -Destination $target -Force
}

Write-Host ""
Write-Host "Installed AEON vLLM launcher files to:" -ForegroundColor Cyan
Write-Host $targetDirFull
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Run download-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.bat to download the model."
Write-Host "2. Run start-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-docker.bat to start vLLM."
Write-Host "3. Run bench-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-context-ladder.bat to reuse the repo benchmark ladder."
Write-Host "4. If LAN clients cannot connect, run allow-aeon-qwen36-vllm-firewall-admin.bat as admin."
Write-Host ""
