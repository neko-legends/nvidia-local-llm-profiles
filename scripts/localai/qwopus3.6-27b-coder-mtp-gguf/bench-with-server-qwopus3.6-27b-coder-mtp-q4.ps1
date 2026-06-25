param(
    [string]$LlamaDir = "D:\Tools\llama.cpp-b9267-cuda13.1",
    [string]$ModelPath = "$PSScriptRoot\..\..\..\..\.local-model-cache\Jackrong\Qwopus3.6-27B-Coder-MTP-GGUF\Qwopus3.6-27B-Coder-MTP-Q4_K_M.gguf",
    [int]$Port = 39186,
    [int]$ContextSize = 262144,
    [int[]]$PromptTokenTargets = @(10000, 200000)
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$bench = Join-Path $repoRoot "scripts\benchmarks\bench-context-ladder.ps1"
$llamaServer = Join-Path $LlamaDir "llama-server.exe"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outLog = Join-Path $repoRoot "logs\qwopus-q4-bench-server-$stamp.out.log"
$errLog = Join-Path $repoRoot "logs\qwopus-q4-bench-server-$stamp.err.log"

if (-not (Test-Path -LiteralPath $llamaServer)) {
    throw "llama-server.exe not found at $llamaServer"
}

if (-not (Test-Path -LiteralPath $ModelPath)) {
    throw "Model not found at $ModelPath"
}
$modelFullPath = (Resolve-Path -LiteralPath $ModelPath).Path

$args = @(
    "--model", $modelFullPath,
    "--alias", "qwopus3.6-27b-coder-mtp-q4-k-m",
    "--host", "0.0.0.0",
    "--port", "$Port",
    "--device", "CUDA0",
    "--gpu-layers", "all",
    "--ctx-size", "$ContextSize",
    "--cache-type-k", "q4_0",
    "--cache-type-v", "q4_0",
    "--flash-attn", "on",
    "--parallel", "1",
    "--cont-batching",
    "--jinja",
    "--metrics",
    "--slots",
    "--reasoning", "off",
    "--spec-type", "ngram-mod,draft-mtp",
    "--spec-draft-n-max", "2",
    "--spec-draft-p-min", "0.0",
    "--spec-ngram-mod-n-match", "24",
    "--spec-ngram-mod-n-min", "48",
    "--spec-ngram-mod-n-max", "64"
)

$process = $null
try {
    $process = Start-Process `
        -FilePath $llamaServer `
        -ArgumentList $args `
        -WorkingDirectory $LlamaDir `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError $errLog `
        -WindowStyle Hidden `
        -PassThru

    Write-Host "Started llama-server PID $($process.Id)"
    Write-Host "Server logs: $errLog"

    $deadline = (Get-Date).AddMinutes(10)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        if ($process.HasExited) {
            throw "llama-server exited early with code $($process.ExitCode). Check $errLog"
        }

        try {
            Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/models" -TimeoutSec 4 | Out-Null
            $ready = $true
            break
        } catch {
            $gpu = & nvidia-smi --query-gpu=memory.used,power.draw,temperature.gpu --format=csv,noheader,nounits --id=0
            Write-Host "Waiting for llama-server: GPU $gpu"
            Start-Sleep -Seconds 10
        }
    }

    if (-not $ready) {
        throw "llama-server did not become ready. Check $errLog"
    }

    & $bench `
        -BaseUrl "http://127.0.0.1:$Port/v1" `
        -Model "qwopus3.6-27b-coder-mtp-q4-k-m" `
        -CasePrefix "qwopus-coder-mtp-q4-ctx256k-mtp" `
        -GpuIndex 0 `
        -PromptTokenTargets $PromptTokenTargets `
        -MaxTokens 1024 `
        -Runs 1 `
        -WarmupRuns 0 `
        -Temperature 0 `
        -Seed 1234

    if ($LASTEXITCODE -ne 0) {
        throw "Benchmark failed with code $LASTEXITCODE"
    }
} finally {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        Write-Host "Stopped llama-server PID $($process.Id)"
    }
}
