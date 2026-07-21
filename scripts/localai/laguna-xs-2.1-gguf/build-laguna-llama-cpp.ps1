param([string]$SourceDir = "", [string]$BuildDir = "")
$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$checkoutParent = Split-Path -Parent $repoRoot
if (-not $SourceDir) { $SourceDir = Join-Path $checkoutParent ".llama-runtimes\laguna-llama-src" }
if (-not $BuildDir) { $BuildDir = Join-Path $SourceDir "build-sm120-ninja" }
$vsRoot = "C:\Program Files\Microsoft Visual Studio\2022\Community"
$devCmd = Join-Path $vsRoot "Common7\Tools\VsDevCmd.bat"
$ninja = Join-Path $vsRoot "Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
foreach ($path in @($devCmd, $ninja)) { if (-not (Test-Path -LiteralPath $path)) { throw "Missing: $path" } }
if (-not (Test-Path -LiteralPath (Join-Path $SourceDir ".git"))) {
    git clone https://github.com/ggml-org/llama.cpp.git $SourceDir
    if ($LASTEXITCODE -ne 0) { throw "llama.cpp clone failed" }
}
git -C $SourceDir fetch origin pull/25165/head:laguna
if ($LASTEXITCODE -ne 0) { throw "Fetching llama.cpp PR 25165 failed" }
git -C $SourceDir checkout laguna
if ($LASTEXITCODE -ne 0) { throw "Checking out Laguna branch failed" }
$command = 'call "{0}" -arch=x64 -host_arch=x64 && cmake -S "{1}" -B "{2}" -G Ninja -DCMAKE_MAKE_PROGRAM="{3}" -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=120 -DCMAKE_BUILD_TYPE=Release && cmake --build "{2}" --target llama-server llama-cli -j 16' -f $devCmd,$SourceDir,$BuildDir,$ninja
cmd.exe /d /s /c $command
if ($LASTEXITCODE -ne 0) { throw "Laguna llama.cpp build failed" }
