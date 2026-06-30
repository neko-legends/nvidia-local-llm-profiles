param(
    [string]$LlamaDir = "",
    [string]$ModelPath = "",
    [int]$Port = 39194,
    [int]$ContextSize = 200000,
    [int[]]$PromptTokenTargets = @(10000, 200000),
    [ValidateSet("ngram-mod,draft-mtp", "draft-mtp")]
    [string]$SpecType = "draft-mtp",
    [int]$SpecDraftNMax = 2,
    [switch]$EnableThinking
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$checkoutParent = Split-Path -Parent $repoRoot
if (-not $ModelPath) {
    $ModelPath = Join-Path $checkoutParent ".local-model-cache\nvidia\Qwen3.6-35B-A3B-NVFP4-MTP-GGUF\qwen3.6-35b-a3b-nvfp4-mtp.gguf"
}

function Resolve-LlamaServer {
    param([string]$Dir)

    if ($Dir) {
        $candidate = Join-Path $Dir "llama-server.exe"
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        throw "llama-server.exe not found at $candidate"
    }

    if ($env:LLAMA_DIR) {
        return Resolve-LlamaServer -Dir $env:LLAMA_DIR
    }

    $command = Get-Command llama-server.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    throw "llama-server.exe not found. Pass -LlamaDir, set LLAMA_DIR, or add llama-server.exe to PATH."
}

$llamaServer = Resolve-LlamaServer -Dir $LlamaDir
$resolvedLlamaDir = Split-Path -Parent $llamaServer
$bench = Join-Path $repoRoot "scripts\benchmarks\bench-context-ladder.ps1"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outLog = Join-Path $repoRoot "logs\qwen36-nvidia-nvfp4-mtp-gguf-bench-server-$stamp.out.log"
$errLog = Join-Path $repoRoot "logs\qwen36-nvidia-nvfp4-mtp-gguf-bench-server-$stamp.err.log"
$modelAlias = "qwen36-35b-a3b-nvfp4-mtp-gguf"
$specSlug = $SpecType.Replace(",", "-").Replace("_", "-")
$ctxSlug = if (($ContextSize % 1000) -eq 0) { "ctx$([int]($ContextSize / 1000))k" } else { "ctx$ContextSize" }
$casePrefix = "qwen36-35b-a3b-nvfp4-mtp-gguf-llamacpp-$ctxSlug-$specSlug-mtpn$SpecDraftNMax"
if (-not $EnableThinking) {
    $casePrefix += "-request-nothink"
}

if (-not (Test-Path -LiteralPath $ModelPath)) {
    throw "Model not found at $ModelPath"
}
$modelFullPath = (Resolve-Path -LiteralPath $ModelPath).Path

$args = @(
    "--model", $modelFullPath,
    "--alias", $modelAlias,
    "--host", "0.0.0.0",
    "--port", "$Port",
    "--device", "CUDA0",
    "--gpu-layers", "all",
    "--gpu-layers-draft", "all",
    "--ctx-size", "$ContextSize",
    "--cache-type-k", "q4_0",
    "--cache-type-v", "q4_0",
    "--cache-type-k-draft", "q4_0",
    "--cache-type-v-draft", "q4_0",
    "--flash-attn", "on",
    "--parallel", "1",
    "--cont-batching",
    "--jinja",
    "--metrics",
    "--slots",
    "--spec-type", $SpecType,
    "--spec-draft-n-max", "$SpecDraftNMax",
    "--spec-draft-p-min", "0.0"
)
if ($SpecType -like "*ngram-mod*") {
    $args += @(
        "--spec-ngram-mod-n-match", "24",
        "--spec-ngram-mod-n-min", "48",
        "--spec-ngram-mod-n-max", "64"
    )
}
if ($EnableThinking) {
    $args += @("--reasoning", "on")
} else {
    $args += @("--reasoning", "off")
}

$process = $null
try {
    $process = Start-Process `
        -FilePath $llamaServer `
        -ArgumentList $args `
        -WorkingDirectory $resolvedLlamaDir `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError $errLog `
        -WindowStyle Hidden `
        -PassThru

    Write-Host "Started llama-server PID $($process.Id)"
    Write-Host "Server logs: $errLog"

    $deadline = (Get-Date).AddMinutes(15)
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
            try {
                $gpu = & nvidia-smi --query-gpu=memory.used,power.draw,temperature.gpu --format=csv,noheader,nounits --id=0
                Write-Host "Waiting for llama-server: GPU $gpu"
            } catch {
                Write-Host "Waiting for llama-server..."
            }
            Start-Sleep -Seconds 10
        }
    }

    if (-not $ready) {
        throw "llama-server did not become ready. Check $errLog"
    }

    foreach ($target in $PromptTokenTargets) {
        $benchArgs = @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", $bench,
            "-BaseUrl", "http://127.0.0.1:$Port/v1",
            "-Model", $modelAlias,
            "-CasePrefix", $casePrefix,
            "-GpuIndex", "0",
            "-PromptTokenTargets", "$target",
            "-MaxTokens", "1024",
            "-Runs", "1",
            "-WarmupRuns", "0",
            "-Temperature", "0",
            "-Seed", "1234"
        )
        if (-not $EnableThinking) {
            $benchArgs += "-DisableThinking"
        }

        & powershell @benchArgs

        if ($LASTEXITCODE -ne 0) {
            throw "Benchmark failed with code $LASTEXITCODE"
        }
    }
} finally {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        Write-Host "Stopped llama-server PID $($process.Id)"
    }
}
