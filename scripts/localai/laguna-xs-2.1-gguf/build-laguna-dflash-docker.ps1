param(
    [string]$BaseImage = "vllm/vllm-openai:nightly",
    [string]$RuntimeImage = "local/lucebox-dflash-sm120:cuda13",
    [string]$BuilderContainer = "lucebox-build-sm120",
    [string]$BuildVolume = "lucebox-build-sm120",
    [string]$ModelVolume = "laguna-xs21-dflash-models",
    [string]$TargetModel = "",
    [string]$DraftModel = "",
    [string]$PrefillDrafter = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$checkoutParent = Split-Path -Parent $repoRoot
if (-not $TargetModel) { $TargetModel = Join-Path $checkoutParent ".local-model-cache\poolside\Laguna-XS-2.1-GGUF\Laguna-XS-2.1-Q4_K_M.gguf" }
if (-not $DraftModel) { $DraftModel = Join-Path $checkoutParent ".local-model-cache\Lucebox\Laguna-XS-2.1-DFlash-GGUF\laguna-xs21-dflash-q4.gguf" }
if (-not $PrefillDrafter) { $PrefillDrafter = Join-Path $checkoutParent ".local-model-cache\Qwen\Qwen3-0.6B-GGUF\Qwen3-0.6B-Q8_0.gguf" }
foreach ($path in @($TargetModel, $DraftModel, $PrefillDrafter)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing model file: $path" }
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw "docker.exe was not found." }

& docker image inspect $RuntimeImage *> $null
if ($LASTEXITCODE -ne 0) {
    & docker volume create $BuildVolume | Out-Null
    & docker container inspect $BuilderContainer *> $null
    if ($LASTEXITCODE -ne 0) {
        & docker run -d --name $BuilderContainer --gpus all -v "${BuildVolume}:/src" --entrypoint bash $BaseImage -lc "sleep infinity" | Out-Null
    } else {
        & docker start $BuilderContainer | Out-Null
    }

    & docker exec $BuilderContainer bash -lc "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends cmake libcurl4-openssl-dev pkg-config git git-lfs"
    if ($LASTEXITCODE -ne 0) { throw "Failed to install Lucebox build dependencies." }
    & docker exec $BuilderContainer bash -lc "test -d /src/lucebox/.git || git clone --recursive --depth 1 https://github.com/Luce-Org/lucebox-hub.git /src/lucebox"
    if ($LASTEXITCODE -ne 0) { throw "Failed to clone Lucebox." }
    & docker exec $BuilderContainer bash -lc "ln -sf libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 && echo /usr/local/cuda/lib64/stubs >/etc/ld.so.conf.d/cuda-stubs.conf && ldconfig"
    & docker exec $BuilderContainer cmake -S /src/lucebox/server -B /src/lucebox/server/build-sm120 -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON -DDFLASH27B_USER_CUDA_ARCHITECTURES=120 -DCMAKE_CUDA_ARCHITECTURES=120
    if ($LASTEXITCODE -ne 0) { throw "Lucebox CMake configure failed." }
    & docker exec $BuilderContainer cmake --build /src/lucebox/server/build-sm120 --target dflash_server --parallel 16
    if ($LASTEXITCODE -ne 0) { throw "Lucebox dflash_server build failed." }
    & docker commit $BuilderContainer $RuntimeImage | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to commit local Lucebox runtime image." }
}

& docker volume create $ModelVolume | Out-Null
& docker run --rm -v "${ModelVolume}:/models" --entrypoint bash $RuntimeImage -lc "test -s /models/target.gguf -a -s /models/draft.gguf -a -s /models/prefill.gguf" *> $null
if ($LASTEXITCODE -ne 0) {
    $target = (Resolve-Path -LiteralPath $TargetModel).Path
    $draft = (Resolve-Path -LiteralPath $DraftModel).Path
    $prefill = (Resolve-Path -LiteralPath $PrefillDrafter).Path
    & docker run --rm `
        -v "${ModelVolume}:/models" `
        --mount "type=bind,source=$target,target=/host/target.gguf,readonly" `
        --mount "type=bind,source=$draft,target=/host/draft.gguf,readonly" `
        --mount "type=bind,source=$prefill,target=/host/prefill.gguf,readonly" `
        --entrypoint bash $RuntimeImage -lc "cp /host/target.gguf /models/target.gguf && cp /host/draft.gguf /models/draft.gguf && cp /host/prefill.gguf /models/prefill.gguf"
    if ($LASTEXITCODE -ne 0) { throw "Failed to populate the native Docker model volume." }
}

Write-Host "Lucebox SM120 runtime and native model volume are ready." -ForegroundColor Green
Write-Host "Start: powershell -ExecutionPolicy Bypass -File $PSScriptRoot\start-laguna-xs-2.1-dflash-docker.ps1"
