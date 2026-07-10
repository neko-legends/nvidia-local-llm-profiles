param(
    [Parameter(Mandatory)]
    [string]$ModelPath,
    [Parameter(Mandatory)]
    [string]$ModelAlias,
    [Parameter(Mandatory)]
    [string]$CasePrefix,
    [Parameter(Mandatory)]
    [int]$Port,
    [string]$LlamaDir = "",
    [int]$ContextSize = 200000,
    [int]$GpuIndex = 0,
    [int]$SpecDraftNMax = 2,
    [switch]$EnableThinking
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$bench = Join-Path $PSScriptRoot "bench-context-ladder.ps1"
$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

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

if (-not (Test-Path -LiteralPath $ModelPath)) {
    throw "Model not found at $ModelPath"
}

$llamaServer = Resolve-LlamaServer -Dir $LlamaDir
$resolvedLlamaDir = Split-Path -Parent $llamaServer
$modelFullPath = (Resolve-Path -LiteralPath $ModelPath).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outLog = Join-Path $logDir "$CasePrefix-bench-server-$stamp.out.log"
$errLog = Join-Path $logDir "$CasePrefix-bench-server-$stamp.err.log"

$serverArgs = @(
    "--model", $modelFullPath,
    "--alias", $ModelAlias,
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
    "--spec-type", "draft-mtp",
    "--spec-draft-n-max", "$SpecDraftNMax",
    "--spec-draft-p-min", "0.0"
)
if ($EnableThinking) {
    $serverArgs += @("--reasoning", "on")
} else {
    $serverArgs += @("--reasoning", "off")
}

$process = $null
try {
    $process = Start-Process `
        -FilePath $llamaServer `
        -ArgumentList $serverArgs `
        -WorkingDirectory $resolvedLlamaDir `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError $errLog `
        -WindowStyle Hidden `
        -PassThru

    Write-Host "Started llama-server PID $($process.Id)"
    Write-Host "Server log: $errLog"

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
            Start-Sleep -Seconds 10
        }
    }
    if (-not $ready) {
        throw "llama-server did not become ready. Check $errLog"
    }

    foreach ($target in @(10000, 200000)) {
        $benchArgs = @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", $bench,
            "-BaseUrl", "http://127.0.0.1:$Port/v1",
            "-Model", $ModelAlias,
            "-CasePrefix", $CasePrefix,
            "-GpuIndex", "$GpuIndex",
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
