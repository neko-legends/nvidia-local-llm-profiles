param(
    # MTP speculative token counts to sweep
    [int[]]$SpecN = @(1, 2, 3, 4, 5),

    # vLLM / Docker settings
    [string]$ModelDir       = "D:/Tools/LocalAI/models/Qwen3.6-27B-Text-NVFP4-MTP",
    [string]$Image          = "vllm/vllm-openai:latest",
    [string]$ContainerName  = "qwen36-text-nvfp4-mtp-vllm",
    [string]$HostAddress    = "127.0.0.1",
    [int]$Port              = 8892,
    [string]$ServedModelName = "qwen3.6-27b-text-nvfp4-mtp",
    [int]$MaxModelLen       = 262144,
    [double]$GpuMemUtil     = 0.93,
    [string]$KvCacheDtype   = "fp8",

    # Bench settings
    [int]$TargetPromptTokens = 262144,
    [int]$MaxTokens          = 1024,
    [int]$Runs               = 3,
    [int]$WarmupRuns         = 1,
    [double]$Temperature     = 0.0,
    [int]$Seed               = 1234,
    [int]$GpuIndex           = 0,

    # How long to wait for vLLM to become healthy (seconds)
    [int]$StartupTimeoutSec  = 360,

    # Where to write individual bench CSVs + summary
    [string]$ResultDir       = ""
)

$ErrorActionPreference = "Stop"

$repoRoot  = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$benchScript = Join-Path $PSScriptRoot "bench-openai-chat-endpoint.ps1"

if (-not $ResultDir) {
    $ResultDir = Join-Path $repoRoot "results\rtx-5090"
}
if (-not (Test-Path -LiteralPath $ResultDir)) {
    New-Item -ItemType Directory -Force -Path $ResultDir | Out-Null
}

$stamp      = Get-Date -Format "yyyyMMdd-HHmmss"
$summaryCsv = Join-Path $ResultDir "qwen-nvfp4-vllm-mtp-sweep-summary-$stamp.csv"
$summaryRows = @()

function Write-Step($msg) {
    Write-Host ""
    Write-Host $msg -ForegroundColor Cyan
}

function Save-Summary {
    $summaryRows | Export-Csv -LiteralPath $summaryCsv -NoTypeInformation -Force
}

function Stop-VllmContainer {
    $running = docker ps --filter "name=^/$ContainerName$" --format "{{.Names}}" 2>$null
    if ($running -eq $ContainerName) {
        Write-Step "Stopping container: $ContainerName"
        docker stop $ContainerName | Out-Null
        Start-Sleep -Seconds 4
    }
    $old = docker ps -a --filter "name=^/$ContainerName$" --format "{{.Names}}" 2>$null
    if ($old -eq $ContainerName) {
        docker rm $ContainerName | Out-Null
    }
}

function Start-VllmContainer {
    param([int]$N)

    $specCfg = "{`"method`":`"qwen3_5_mtp`",`"num_speculative_tokens`":$N}"

    $dockerArgs = @(
        "run", "--rm",
        "--name", $ContainerName,
        "--gpus", "all",
        "--ipc", "host",
        "-p", "${HostAddress}:${Port}:8000",
        "-v", "${ModelDir}:/model:ro",
        "-e", "CUDA_DEVICE_ORDER=PCI_BUS_ID",
        "-e", "CUDA_VISIBLE_DEVICES=0",
        "-d",  # detached
        $Image,
        "/model",
        "--served-model-name", $ServedModelName,
        "--host", "0.0.0.0",
        "--port", "8000",
        "--trust-remote-code",
        "--quantization", "modelopt",
        "--language-model-only",
        "--max-model-len", "$MaxModelLen",
        "--max-num-seqs", "1",
        "--gpu-memory-utilization", "$GpuMemUtil",
        "--reasoning-parser", "qwen3",
        "--kv-cache-dtype", $KvCacheDtype,
        "--speculative-config=$specCfg"
    )

    Write-Step "Starting vLLM (MTP n=$N, ctx=$MaxModelLen, kv=$KvCacheDtype, gpu-mem=$GpuMemUtil)"
    & docker @dockerArgs | Out-Null
}

function Wait-VllmReady {
    param([int]$N)

    $url = "http://$HostAddress`:$Port/health"
    Write-Host "Waiting for vLLM to become healthy (timeout ${StartupTimeoutSec}s)..."
    for ($i = 0; $i -lt $StartupTimeoutSec; $i++) {
        Start-Sleep -Seconds 1
        $dead = docker ps --filter "name=^/$ContainerName$" --format "{{.Names}}" 2>$null
        if ($dead -ne $ContainerName) {
            throw "Container exited unexpectedly during startup for MTP n=$N"
        }
        try {
            $r = Invoke-RestMethod -Uri $url -TimeoutSec 3
            if ($r.status -eq "ok") {
                Write-Host "vLLM ready after $i seconds."
                return
            }
        } catch { }
    }
    throw "vLLM did not become healthy within ${StartupTimeoutSec}s for MTP n=$N"
}

# ── Main sweep ────────────────────────────────────────────────────────────────

Write-Step "Qwen NVFP4 vLLM MTP sweep"
Write-Host "Spec N values : $($SpecN -join ', ')"
Write-Host "Context       : $MaxModelLen"
Write-Host "Prompt target : $TargetPromptTokens"
Write-Host "Gen tokens    : $MaxTokens (warmup=$WarmupRuns, runs=$Runs)"
Write-Host "KV cache dtype: $KvCacheDtype"
Write-Host "GPU mem util  : $GpuMemUtil"
Write-Host "Summary CSV   : $summaryCsv"

foreach ($n in $SpecN) {
    $caseName = "qwen-nvfp4-mtp-n$n-ctx256k-prompt256k-gen$MaxTokens"
    $outCsv   = Join-Path $ResultDir "$caseName-$stamp.csv"

    Write-Step "=== MTP n=$n ==="

    $row = [pscustomobject]@{
        case                  = $caseName
        spec_n                = $n
        max_model_len         = $MaxModelLen
        kv_cache_dtype        = $KvCacheDtype
        gpu_mem_util          = $GpuMemUtil
        target_prompt_tokens  = $TargetPromptTokens
        max_tokens            = $MaxTokens
        runs                  = $Runs
        warmup_runs           = $WarmupRuns
        started_at            = ""
        ended_at              = ""
        elapsed_seconds       = $null
        avg_wall_completion_tps = $null
        status                = "running"
        exit_code             = $null
        result_csv            = $outCsv
    }
    $summaryRows += $row
    Save-Summary

    Stop-VllmContainer
    Start-VllmContainer -N $n

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $startedAt = Get-Date
    $row.started_at = $startedAt.ToString("o")
    Save-Summary

    try {
        Wait-VllmReady -N $n

        # Give it 10 more seconds to fully settle after /health returns ok
        Start-Sleep -Seconds 10

        & powershell -NoProfile -ExecutionPolicy Bypass -File $benchScript `
            -BaseUrl "http://$HostAddress`:$Port/v1" `
            -Model $ServedModelName `
            -CaseName $caseName `
            -GpuIndex $GpuIndex `
            -MaxTokens $MaxTokens `
            -Runs $Runs `
            -WarmupRuns $WarmupRuns `
            -Temperature $Temperature `
            -Seed $Seed `
            -PromptStyle BookContext `
            -TargetPromptTokens $TargetPromptTokens `
            -OutCsv $outCsv
        $exitCode = $LASTEXITCODE

    } catch {
        Write-Warning "MTP n=$n failed: $_"
        $exitCode = 1
    }

    $timer.Stop()
    $endedAt = Get-Date
    $row.ended_at         = $endedAt.ToString("o")
    $row.elapsed_seconds  = [math]::Round($timer.Elapsed.TotalSeconds, 3)
    $row.exit_code        = $exitCode
    $row.status           = if ($exitCode -eq 0) { "ok" } else { "failed" }

    # Pull avg tps from the individual bench CSV
    if ((Test-Path -LiteralPath $outCsv) -and $exitCode -eq 0) {
        $measured = @(Import-Csv -LiteralPath $outCsv | Where-Object { $_.warmup -ne "True" })
        if ($measured.Count -gt 0) {
            $row.avg_wall_completion_tps = [math]::Round(
                (($measured | ForEach-Object { [double]$_.wall_completion_tps }) |
                 Measure-Object -Average).Average, 3)
        }
    }

    Save-Summary
    Write-Host "n=$n done: status=$($row.status) avg_tps=$($row.avg_wall_completion_tps)" -ForegroundColor Green
}

# Final container teardown
Stop-VllmContainer

Write-Step "Sweep complete"
Write-Host ""
Write-Host "Summary:"
$summaryRows | Format-Table spec_n, status, avg_wall_completion_tps, elapsed_seconds -AutoSize
Write-Host ""
Write-Host "Wrote summary: $summaryCsv" -ForegroundColor Green
