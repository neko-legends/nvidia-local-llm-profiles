param(
    [string]$TargetDir = "$PSScriptRoot\..\installed-aeon-ornith-nvfp4"
)

$ErrorActionPreference = "Stop"

$sourceDir = $PSScriptRoot
$targetDirFull = [System.IO.Path]::GetFullPath($TargetDir)

if (-not (Test-Path -LiteralPath $targetDirFull)) {
    New-Item -ItemType Directory -Path $targetDirFull | Out-Null
}

$files = @(
    "download-aeon-ornith-1.0-35b-nvfp4.bat",
    "start-aeon-ornith-1.0-35b-nvfp4-vllm-docker.bat",
    "bench-aeon-ornith-1.0-35b-nvfp4-two-point.bat",
    "allow-aeon-ornith-nvfp4-firewall-admin.bat",
    "aeon-ornith-1.0-35b-nvfp4-notes.md"
)

foreach ($file in $files) {
    $source = Join-Path $sourceDir $file
    $target = Join-Path $targetDirFull $file
    Copy-Item -LiteralPath $source -Destination $target -Force
}

Write-Host ""
Write-Host "Installed AEON Ornith NVFP4 launcher files to:" -ForegroundColor Cyan
Write-Host $targetDirFull
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Run download-aeon-ornith-1.0-35b-nvfp4.bat to download the model snapshot."
Write-Host "2. Run start-aeon-ornith-1.0-35b-nvfp4-vllm-docker.bat to start vLLM."
Write-Host "3. Run bench-aeon-ornith-1.0-35b-nvfp4-two-point.bat after the server is ready."
Write-Host "4. If LAN clients cannot connect, run allow-aeon-ornith-nvfp4-firewall-admin.bat as admin."
Write-Host ""
