$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$checkoutParent = (Resolve-Path (Join-Path $scriptDir "..\..\..\..")).Path
$runtimeRoot = Join-Path $checkoutParent ".llama-runtimes"
$sourceDir = Join-Path $runtimeRoot "prism-llama-src"
$buildDir = Join-Path $sourceDir "build-sm120"
$installDir = Join-Path $runtimeRoot "prism-62061f9-sm120-win-cuda12.8"
$commit = "62061f91088281e65071cc38c5f69ee95c39f14e"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

foreach ($command in @("git", "cmake")) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "$command is required." }
}
if (-not (Test-Path $vswhere)) { throw "Visual Studio Installer's vswhere.exe was not found." }
$vs = (& $vswhere -latest -products * -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath).Trim()
if (-not $vs) { throw "Visual Studio 2022 C++ Build Tools were not found." }
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
$ninja = Join-Path $vs "Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
$cuda = if ($env:CUDA_PATH) { $env:CUDA_PATH } else { "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8" }
if (-not (Test-Path (Join-Path $cuda "bin\nvcc.exe"))) { throw "CUDA 12.8+ toolkit was not found. Set CUDA_PATH." }

New-Item -ItemType Directory -Force -Path $runtimeRoot, $installDir | Out-Null
if (-not (Test-Path (Join-Path $sourceDir ".git"))) {
    & git clone https://github.com/PrismML-Eng/llama.cpp.git $sourceDir
    if ($LASTEXITCODE) { throw "git clone failed." }
}
& git -C $sourceDir fetch --depth 1 origin $commit
if ($LASTEXITCODE) { throw "git fetch failed." }
& git -C $sourceDir checkout --detach $commit
if ($LASTEXITCODE) { throw "git checkout failed." }

$configure = "call `"$vcvars`" >nul && set `"CUDA_PATH=$cuda`" && cmake -S . -B build-sm120 -G Ninja -DCMAKE_MAKE_PROGRAM=`"$ninja`" -DCMAKE_BUILD_TYPE=Release -DGGML_CUDA=ON -DGGML_CUDA_FA_ALL_QUANTS=ON -DCMAKE_CUDA_ARCHITECTURES=120 -DCMAKE_CUDA_FLAGS=-allow-unsupported-compiler"
& cmd /d /s /c $configure
if ($LASTEXITCODE) { throw "CMake configure failed." }
& cmd /d /s /c "call `"$vcvars`" >nul && cmake --build build-sm120 --target llama-server -j 24"
if ($LASTEXITCODE) { throw "CMake build failed." }

Copy-Item -Path (Join-Path $buildDir "bin\*") -Destination $installDir -Recurse -Force
if (-not (Test-Path (Join-Path $installDir "llama-server.exe"))) { throw "Built llama-server.exe was not installed." }
Write-Host "Blackwell-native PrismML runtime installed at $installDir" -ForegroundColor Green
