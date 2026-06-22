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

$files = @(
    "download-qwen3.6-27B-Text-NVFP4-MTP.bat",
    "download-to-LocalAI-models.bat",
    "start-qwen3.6-27B-Text-NVFP4-MTP-server.bat",
    "Start-Qwen3.6-27B-Text-NVFP4-MTP-vLLM.ps1",
    "qwen3.6-27B-Text-NVFP4-MTP-server-notes.md"
)

foreach ($file in $files) {
    $source = Join-Path $sourceDir $file
    $target = Join-Path $targetDirFull $file
    Copy-Item -LiteralPath $source -Destination $target -Force
}

$modelDir = Join-Path $targetDirFull "models\Qwen3.6-27B-Text-NVFP4-MTP"
if (-not (Test-Path -LiteralPath $modelDir)) {
    New-Item -ItemType Directory -Path $modelDir | Out-Null
}

$shortcutPath = Join-Path $targetDirFull "Launch Qwen Server.lnk"
$launcherPath = Join-Path $targetDirFull "start-qwen3.6-27B-Text-NVFP4-MTP-server.bat"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "$env:WINDIR\System32\cmd.exe"
$shortcut.Arguments = "/k `"$launcherPath`""
$shortcut.WorkingDirectory = $targetDirFull
$shortcut.IconLocation = "$env:WINDIR\System32\shell32.dll,13"
$shortcut.Description = "Launch Qwen3.6 27B Text NVFP4 MTP vLLM server"
$shortcut.WindowStyle = 1
$shortcut.Save()

Write-Host ""
Write-Host "Installed Qwen3.6 Text NVFP4 MTP launchers to:" -ForegroundColor Cyan
Write-Host $targetDirFull
Write-Host "Updated shortcut:"
Write-Host $shortcutPath
Write-Host ""
Write-Host "Next:"
Write-Host "1. Run download-qwen3.6-27B-Text-NVFP4-MTP.bat (free HF account may be required)"
Write-Host "2. Edit ModelDir in Start-Qwen3.6-27B-Text-NVFP4-MTP-vLLM.ps1 if you saved the model elsewhere"
Write-Host "3. Double-click Launch Qwen Server.lnk (or run start-qwen3.6-27B-Text-NVFP4-MTP-server.bat)"
Write-Host ""
