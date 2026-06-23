param(
    # ModelDir: full path to the downloaded Qwen3.6-27B-Text-NVFP4-MTP folder.
    # Default assumes the model is in a "models" subfolder next to this script
    # (which is where the download scripts save it). Edit if you store it elsewhere.
    [string]$ModelDir = "$PSScriptRoot\models\Qwen3.6-27B-Text-NVFP4-MTP",
    [string]$Image = "vllm/vllm-openai:latest",
    [string]$ContainerName = "qwen36-text-nvfp4-mtp-vllm",
    [string]$HostAddress = "127.0.0.1",
    [int]$Port = 8892,
    [string]$ServedModelName = "qwen3.6-27b-text-nvfp4-mtp",
    [int]$MaxModelLen = 262144,
    [double]$GpuMemoryUtilization = 0.90,
    [int]$MaxNumSeqs = 1,
    [string]$TensorParallelSize = "1",
    [string]$CudaVisibleDevices = "0",
    [string]$KvCacheDtype = "fp8",
    [string]$SpeculativeConfig = '{"method":"qwen3_5_mtp","num_speculative_tokens":3}',
    [switch]$NoSpeculative
)

$ErrorActionPreference = "Stop"

function Write-Step($Message) {
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
}

function Test-DockerImage($ImageName) {
    $imageId = docker image inspect $ImageName --format "{{.Id}}" 2>$null
    return -not [string]::IsNullOrWhiteSpace($imageId)
}

function Test-ModelReady($Path) {
    if (-not (Test-Path -LiteralPath (Join-Path $Path "config.json"))) { return $false }
    # Accept either a single-shard model.safetensors or a multi-shard index file
    $hasSingle = Test-Path -LiteralPath (Join-Path $Path "model.safetensors")
    $hasIndex  = Test-Path -LiteralPath (Join-Path $Path "model.safetensors.index.json")
    return ($hasSingle -or $hasIndex)
}

$ModelDir = [System.IO.Path]::GetFullPath($ModelDir)
$serverUrl = "http://$HostAddress`:$Port"

$maxLenFile = Join-Path $ModelDir ".recommended-max-model-len"
if (Test-Path -LiteralPath $maxLenFile) {
    $fileValue = (Get-Content -LiteralPath $maxLenFile -TotalCount 1).Trim()
    if ($fileValue -match "^\d+$") {
        $MaxModelLen = [int]$fileValue
    }
}

Write-Step "Qwen3.6 Text NVFP4 MTP vLLM server"
Write-Host "Model folder: $ModelDir"
Write-Host "Server URL:   $serverUrl/v1"
Write-Host "Model name:   $ServedModelName"
Write-Host "Context:      $MaxModelLen tokens"
Write-Host ""
Write-Host "Hermes provider: custom:qwen36-text-nvfp4-mtp-local"
Write-Host "Hermes model:    $ServedModelName"
Write-Host "Hermes base URL: $serverUrl/v1"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker was not found. Install or start Docker Desktop, then run this launcher again."
}

try { docker info 2>&1 | Out-Null } catch {}

if (-not (Test-ModelReady $ModelDir)) {
    throw "The model is not fully downloaded yet. Run download-qwen3.6-27B-Text-NVFP4-MTP.bat, then start this launcher again."
}

if (-not (Test-DockerImage $Image)) {
    Write-Step "Pulling vLLM image: $Image"
    docker pull $Image
}

$running = docker ps --filter "name=^/$ContainerName$" --format "{{.Names}}"
if ($running -eq $ContainerName) {
    Write-Step "Stopping existing container: $ContainerName"
    docker stop $ContainerName | Out-Null
}

$old = docker ps -a --filter "name=^/$ContainerName$" --format "{{.Names}}"
if ($old -eq $ContainerName) {
    docker rm $ContainerName | Out-Null
}

Write-Step "Starting vLLM"
Write-Host "In Hermes, select:"
Write-Host "/model custom:qwen36-text-nvfp4-mtp-local:$ServedModelName"
Write-Host ""
Write-Host "This launcher defaults to the RTX 5090 256K context benchmark profile."
Write-Host "If startup fails, retry with a lower -MaxModelLen value."
Write-Host ""

$dockerArgs = @(
    "run", "--rm",
    "--name", $ContainerName,
    "--gpus", "all",
    "--ipc", "host",
    "-p", "$HostAddress`:$Port`:8000",
    "-v", "$ModelDir`:/model:ro",
    "-e", "CUDA_DEVICE_ORDER=PCI_BUS_ID",
    "-e", "CUDA_VISIBLE_DEVICES=$CudaVisibleDevices",
    $Image,
    "/model",
    "--served-model-name", $ServedModelName,
    "--host", "0.0.0.0",
    "--port", "8000",
    "--trust-remote-code",
    "--quantization", "modelopt",
    "--language-model-only",
    "--max-model-len", "$MaxModelLen",
    "--max-num-seqs", "$MaxNumSeqs",
    "--gpu-memory-utilization", "$GpuMemoryUtilization",
    "--reasoning-parser", "qwen3"
)

if (-not [string]::IsNullOrWhiteSpace($KvCacheDtype)) {
    $dockerArgs += @("--kv-cache-dtype", $KvCacheDtype)
}

if (-not $NoSpeculative) {
    $dockerArgs += @("--speculative-config", $SpeculativeConfig)
}

if ([int]$TensorParallelSize -gt 1) {
    $dockerArgs += @("--tensor-parallel-size", "$TensorParallelSize")
}

& docker @dockerArgs
