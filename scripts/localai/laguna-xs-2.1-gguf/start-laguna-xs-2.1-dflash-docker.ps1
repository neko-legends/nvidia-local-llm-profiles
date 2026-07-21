param(
    [int]$Port = 39204,
    [int]$GpuIndex = 0,
    [int]$ContextSize = 262144,
    [int]$KvFlashTokens = 8192,
    [int]$ChunkSize = 1024,
    [int]$FaWindow = 2048,
    [string]$Image = "local/lucebox-dflash-sm120:cuda13",
    [string]$BuildVolume = "lucebox-build-sm120",
    [string]$ModelVolume = "laguna-xs21-dflash-models"
)

$ErrorActionPreference = "Stop"
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw "docker.exe was not found." }
& docker image inspect $Image *> $null
if ($LASTEXITCODE -ne 0) { throw "Missing local Lucebox image '$Image'. Run build-laguna-dflash-docker.ps1 first." }
foreach ($volume in @($BuildVolume, $ModelVolume)) {
    & docker volume inspect $volume *> $null
    if ($LASTEXITCODE -ne 0) { throw "Missing Docker volume '$volume'. Run build-laguna-dflash-docker.ps1 first." }
}

$server = "/src/lucebox/server/build-sm120/dflash_server"
$modelName = "laguna-xs-2.1-q4-k-m-dflash"

& docker run --rm --name laguna-xs21-dflash `
    --gpus all `
    -e "CUDA_VISIBLE_DEVICES=$GpuIndex" `
    -p "${Port}:8080" `
    -v "${BuildVolume}:/src" `
    -v "${ModelVolume}:/models:ro" `
    --entrypoint $server `
    $Image `
    /models/target.gguf `
    --draft /models/draft.gguf `
    --prefill-drafter /models/prefill.gguf `
    --max-ctx $ContextSize `
    --kvflash $KvFlashTokens `
    --chunk $ChunkSize `
    --fa-window $FaWindow `
    --host 0.0.0.0 `
    --port 8080 `
    --model-name $modelName

if ($LASTEXITCODE -ne 0) { throw "Lucebox container exited with code $LASTEXITCODE." }
