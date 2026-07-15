$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$checkoutParent = (Resolve-Path (Join-Path $scriptDir "..\..\..\..")).Path
$runtimeRoot = Join-Path $checkoutParent ".llama-runtimes"
$sourceDir = Join-Path $runtimeRoot "buun-llama-cpp-dflash-src"
$buildDir = Join-Path $sourceDir "build-sm120-cuda13.3-pinned-v3"
$commit = "34501c54161d2c28842eb37f8be090387819adf7"
$installDir = Join-Path $runtimeRoot "buun-dflash-34501c5-sm120-win-cuda13.3"
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

foreach ($command in @("git", "cmake")) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "$command is required." }
}
if (-not (Test-Path $vswhere)) { throw "Visual Studio Installer's vswhere.exe was not found." }
$vs = (& $vswhere -latest -products * -version "[17.0,18.0)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath).Trim()
if (-not $vs) { throw "Visual Studio 2022 C++ Build Tools were not found." }
$vcvars = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
$ninja = Join-Path $vs "Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
$portableCuda = Join-Path $runtimeRoot "cuda-13.3.1-portable"
$cuda = if (Test-Path (Join-Path $portableCuda "bin\nvcc.exe")) { $portableCuda } elseif ($env:CUDA_PATH) { $env:CUDA_PATH } else { "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.3" }
if (-not (Test-Path (Join-Path $cuda "bin\nvcc.exe"))) { throw "CUDA 13.3 toolkit was not found. Set CUDA_PATH or run bootstrap-cuda-13.3-portable.ps1." }

New-Item -ItemType Directory -Force -Path $runtimeRoot, $installDir | Out-Null
if (-not (Test-Path (Join-Path $sourceDir ".git"))) {
    & git clone https://github.com/spiritbuun/buun-llama-cpp.git $sourceDir
    if ($LASTEXITCODE) { throw "git clone failed." }
}
& git -C $sourceDir fetch --depth 1 origin $commit
if ($LASTEXITCODE) { throw "git fetch failed." }
& git -C $sourceDir checkout --detach $commit
if ($LASTEXITCODE) { throw "git checkout failed." }
& git -C $sourceDir checkout -- ggml/src/ggml-cuda/CMakeLists.txt
if ($LASTEXITCODE) { throw "Failed to restore the pinned fork CMake configuration." }
$tcqGuardPatch = Join-Path $scriptDir "dflash-q4-kv-tcq-guard.patch"
$fattnSource = Join-Path $sourceDir "ggml\src\ggml-cuda\fattn.cu"
if (-not (Select-String -LiteralPath $fattnSource -SimpleMatch 'Turbo codebooks are irrelevant' -Quiet)) {
    & git -C $sourceDir apply $tcqGuardPatch
    if ($LASTEXITCODE) { throw "DFlash q4_0 KV TCQ guard patch failed." }
}
$tcqAlphaGuardPatch = Join-Path $scriptDir "dflash-q4-kv-tcq-alpha-guard.patch"
if (-not (Select-String -LiteralPath $fattnSource -SimpleMatch 'TCQ alpha constants are irrelevant' -Quiet)) {
    & git -C $sourceDir apply $tcqAlphaGuardPatch
    if ($LASTEXITCODE) { throw "DFlash q4_0 KV TCQ alpha guard patch failed." }
}
$lowAcceptPatch = Join-Path $scriptDir "dflash-low-accept-gpu-bypass.patch"
$speculativeSource = Join-Path $sourceDir "common\speculative.cpp"
if (-not (Select-String -LiteralPath $speculativeSource -SimpleMatch 'GPU-only low-acceptance bypass' -Quiet)) {
    & git -C $sourceDir apply $lowAcceptPatch
    if ($LASTEXITCODE) { throw "DFlash GPU-only low-acceptance bypass patch failed." }
}
$perSlotAcceptPatch = Join-Path $scriptDir "dflash-per-slot-accept.patch"
$serverContextSource = Join-Path $sourceDir "tools\server\server-context.cpp"
if (-not (Select-String -LiteralPath $serverContextSource -SimpleMatch 'Per-slot DFlash owns its speculative state' -Quiet)) {
    & git -C $sourceDir apply $perSlotAcceptPatch
    if ($LASTEXITCODE) { throw "DFlash per-slot acceptance callback patch failed." }
}
$captureTogglePatch = Join-Path $scriptDir "dflash-gpu-bypass-capture-toggle.patch"
$speculativeHeader = Join-Path $sourceDir "common\speculative.h"
if (-not (Select-String -LiteralPath $speculativeHeader -SimpleMatch 'common_speculative_start_request' -Quiet)) {
    & git -C $sourceDir apply $captureTogglePatch
    if ($LASTEXITCODE) { throw "DFlash GPU bypass capture toggle patch failed." }
}
$hiddenCapturePatch = Join-Path $scriptDir "dflash-hidden-capture-toggle.patch"
$llamaHeader = Join-Path $sourceDir "include\llama.h"
if (-not (Select-String -LiteralPath $llamaHeader -SimpleMatch 'llama_set_dflash_hidden_capture' -Quiet)) {
    & git -C $sourceDir apply $hiddenCapturePatch
    if ($LASTEXITCODE) { throw "DFlash hidden capture toggle patch failed." }
}
$nvcc = Join-Path $cuda "bin\nvcc.exe"
$configure = "call `"$vcvars`" >nul && set `"CUDA_PATH=$cuda`" && cmake -S `"$sourceDir`" -B `"$buildDir`" -G Ninja -DCMAKE_MAKE_PROGRAM=`"$ninja`" -DCMAKE_BUILD_TYPE=Release -DCUDAToolkit_ROOT=`"$cuda`" -DCMAKE_CUDA_COMPILER=`"$nvcc`" -DGGML_CUDA=ON -DGGML_NATIVE=ON -DGGML_CUDA_FA=ON -DGGML_CUDA_FA_ALL_QUANTS=ON -DLLAMA_BUILD_SERVER=ON -DCMAKE_CUDA_ARCHITECTURES=120"
& cmd /d /s /c $configure
if ($LASTEXITCODE) { throw "CMake configure failed." }
& cmd /d /s /c "call `"$vcvars`" >nul && cmake --build `"$buildDir`" --target llama-server -j 24"
if ($LASTEXITCODE) { throw "CMake build failed." }

Copy-Item -Path (Join-Path $buildDir "bin\*") -Destination $installDir -Recurse -Force
Copy-Item -Path (Join-Path $cuda "bin\x64\*.dll") -Destination $installDir -Force
if (-not (Test-Path (Join-Path $installDir "llama-server.exe"))) { throw "Built llama-server.exe was not installed." }
Write-Host "Blackwell-native DFlash runtime installed at $installDir" -ForegroundColor Green
