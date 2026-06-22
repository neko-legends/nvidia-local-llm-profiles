param(
    # TargetDir: where the launcher scripts are copied.
    # Default: an "installed" folder next to this script.
    # Override to install somewhere else, e.g.:
    #   .\install-all-localai-launchers.ps1 -TargetDir "C:\LocalAI"
    [string]$TargetDir = "$PSScriptRoot\installed"
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$packs = @(
    "qwen3.6-27b-text-nvfp4-mtp",
    "qwopus3.6-27b-coder-mtp-gguf"
)

foreach ($pack in $packs) {
    $installer = Join-Path $root "$pack\install-to-LocalAI.ps1"
    if (-not (Test-Path -LiteralPath $installer)) {
        throw "Missing pack installer: $installer"
    }

    Write-Host ""
    Write-Host "Installing $pack" -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $installer -TargetDir $TargetDir
}

Write-Host ""
Write-Host "All NVIDIA local LLM launcher packs installed to:" -ForegroundColor Green
Write-Host ([System.IO.Path]::GetFullPath($TargetDir))
Write-Host ""
