$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$checkoutParent = (Resolve-Path (Join-Path $scriptDir "..\..\..\..")).Path
$runtimeRoot = Join-Path $checkoutParent ".llama-runtimes"
$downloadDir = Join-Path $runtimeRoot "downloads"
$installDir = Join-Path $runtimeRoot "llama-b10068-bin-win-cuda-13.3-x64"
$baseUrl = "https://github.com/ggml-org/llama.cpp/releases/download/b10068"
$archives = @(
    "llama-b10068-bin-win-cuda-13.3-x64.zip",
    "cudart-llama-bin-win-cuda-13.3-x64.zip"
)

New-Item -ItemType Directory -Force -Path $downloadDir, $installDir | Out-Null
foreach ($archive in $archives) {
    $destination = Join-Path $downloadDir $archive
    if (-not (Test-Path -LiteralPath $destination)) {
        Invoke-WebRequest -Uri "$baseUrl/$archive" -OutFile $destination
    }
    Expand-Archive -LiteralPath $destination -DestinationPath $installDir -Force
}

$server = Get-ChildItem -LiteralPath $installDir -Filter "llama-server.exe" -File -Recurse | Select-Object -First 1
if (-not $server) { throw "llama-server.exe was not found after extracting b10068." }
if ($server.DirectoryName -ne $installDir) {
    Copy-Item -Path (Join-Path $server.DirectoryName "*") -Destination $installDir -Recurse -Force
}
if (-not (Test-Path -LiteralPath (Join-Path $installDir "llama-server.exe"))) {
    throw "llama-server.exe was not installed at $installDir"
}
Write-Host "llama.cpp b10068 CUDA 13.3 installed at $installDir" -ForegroundColor Green
