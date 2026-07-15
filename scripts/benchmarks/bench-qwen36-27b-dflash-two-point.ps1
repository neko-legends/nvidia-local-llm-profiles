param(
    [string]$LlamaDir = "",
    [string]$TargetModel = "",
    [string]$DraftModel = "",
    [int]$Port = 39201,
    [int]$ContextSize = 200000,
    [int[]]$PromptTokenTargets = @(10000, 200000)
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$checkoutParent = Split-Path -Parent $repoRoot
if (-not $LlamaDir) { $LlamaDir = Join-Path $checkoutParent ".llama-runtimes\buun-dflash-34501c5-sm120-win-cuda13.3" }
if (-not $TargetModel) { $TargetModel = Join-Path $checkoutParent ".local-model-cache\unsloth\Qwen3.6-27B-GGUF\Qwen3.6-27B-Q4_K_M.gguf" }
if (-not $DraftModel) { $DraftModel = Join-Path $checkoutParent ".local-model-cache\spiritbuun\Qwen3.6-27B-DFlash-GGUF\dflash-draft-3.6-q8_0.gguf" }

$server = Join-Path $LlamaDir "llama-server.exe"
foreach ($path in @($server, $TargetModel, $DraftModel)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required file not found: $path" }
}

$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outLog = Join-Path $logDir "qwen36-27b-dflash-bench-$stamp.out.log"
$errLog = Join-Path $logDir "qwen36-27b-dflash-bench-$stamp.err.log"
$alias = "qwen36-27b-q4-k-m-dflash-q8-0"
$casePrefix = "qwen36-27b-q4-k-m-dflash-q8-0-buun-34501c5-sm120a-ctx$([int]($ContextSize / 1000))k-nothink"
$bench = Join-Path $PSScriptRoot "bench-context-ladder.ps1"
$args = @(
    "--model", (Resolve-Path $TargetModel).Path,
    "--model-draft", (Resolve-Path $DraftModel).Path,
    "--alias", $alias,
    "--host", "127.0.0.1", "--port", "$Port",
    "--device", "CUDA0", "--device-draft", "CUDA0",
    "--gpu-layers", "all", "--gpu-layers-draft", "all",
    "--ctx-size", "$ContextSize",
    "--cache-type-k", "q4_0", "--cache-type-v", "q4_0",
    "--cache-type-k-draft", "q4_0", "--cache-type-v-draft", "q4_0",
    "--flash-attn", "on", "--parallel", "1", "--cont-batching",
    "--batch-size", "8192", "--ubatch-size", "2048",
    "--spec-dflash-default",
    "--jinja", "--reasoning", "off",
    "--metrics", "--slots", "-lv", "4"
)

$process = $null
try {
    $process = Start-Process -FilePath $server -ArgumentList $args -WorkingDirectory $LlamaDir `
        -RedirectStandardOutput $outLog -RedirectStandardError $errLog -WindowStyle Hidden -PassThru
    Write-Host "Started DFlash server PID $($process.Id); log: $errLog"
    $deadline = (Get-Date).AddMinutes(15)
    do {
        if ($process.HasExited) { throw "DFlash server exited early with code $($process.ExitCode). See $errLog" }
        try { Invoke-RestMethod "http://127.0.0.1:$Port/v1/models" -TimeoutSec 3 | Out-Null; $ready = $true } catch {
            $gpu = & nvidia-smi --query-gpu=memory.used,memory.free,temperature.gpu --format=csv,noheader,nounits --id=0
            Write-Host "Waiting for model load: GPU $gpu"
            Start-Sleep -Seconds 10
        }
    } while (-not $ready -and (Get-Date) -lt $deadline)
    if (-not $ready) { throw "DFlash server did not become ready. See $errLog" }

    $placementLog = Get-Content -LiteralPath $errLog -Raw
    $fullOffloads = [regex]::Matches($placementLog, 'offloaded\s+(\d+)/\1 layers to GPU').Count
    $cuda0Buffers = [regex]::Matches($placementLog, 'CUDA0 model buffer size').Count
    if ($fullOffloads -lt 2 -or $cuda0Buffers -lt 2 -or $placementLog -match 'CUDA1 model buffer size') {
        throw "GPU-only placement check failed: target and draft must both be fully offloaded to CUDA0. See $errLog"
    }
    Write-Host "GPU-only placement verified: target and draft fully offloaded to CUDA0." -ForegroundColor Green

    & $bench `
        -BaseUrl "http://127.0.0.1:$Port/v1" -Model $alias -CasePrefix $casePrefix `
        -GpuIndex 0 -PromptTokenTargets $PromptTokenTargets -MaxTokens 1024 -Runs 1 `
        -WarmupRuns 0 -Temperature 0 -Seed 1234 -DisableThinking
    if (-not $?) { throw "Benchmark failed." }
    Write-Host "Server timing log: $errLog" -ForegroundColor Green
} finally {
    if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
