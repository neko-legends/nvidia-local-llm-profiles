param(
    [string]$TargetDir = "D:\Tools\LocalAI"
)

$ErrorActionPreference = "Stop"

$targetDirFull = [System.IO.Path]::GetFullPath($TargetDir)
$shortcutPath = Join-Path $targetDirFull "Launch Qwen Server.lnk"
$launcherPath = Join-Path $targetDirFull "start-qwen3.6-27B-Text-NVFP4-MTP-server.bat"

if (-not (Test-Path -LiteralPath $launcherPath)) {
    throw "Missing launcher at $launcherPath. Run install-to-LocalAI.bat first."
}

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
Write-Host "Updated shortcut:" -ForegroundColor Cyan
Write-Host $shortcutPath
Write-Host ""
Write-Host "It now runs:"
Write-Host $launcherPath
Write-Host ""
