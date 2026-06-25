param(
    [string]$LlamaDir = "D:\Tools\llama.cpp-b9267-cuda13.1",
    [string]$ModelPath = "D:\forPublic\.local-model-cache\deepreinforce-ai\Ornith-1.0-35B-GGUF\ornith-1.0-35b-Q4_K_M.gguf",
    [int]$Port = 39188,
    [int]$ContextSize = 262144,
    [int]$MaxTokens = 1024,
    [int]$Runs = 1,
    [int]$WarmupRuns = 0,
    [int]$StartupTimeoutMinutes = 10,
    [switch]$NoThinking
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$bench = Join-Path $repoRoot "scripts\benchmarks\bench-openai-chat-endpoint.ps1"
$llamaServer = Join-Path $LlamaDir "llama-server.exe"
$prompt10k = "benchmarks\prompts\book-context-10k.txt"
$prompt200k = "benchmarks\prompts\book-context-200k.txt"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outLog = Join-Path $repoRoot "logs\ornith-q4km-bench-server-$stamp.out.log"
$errLog = Join-Path $repoRoot "logs\ornith-q4km-bench-server-$stamp.err.log"

if (-not (Test-Path -LiteralPath $llamaServer)) {
    throw "llama-server.exe not found at $llamaServer"
}

if (-not (Test-Path -LiteralPath $ModelPath)) {
    throw "Model not found at $ModelPath"
}

foreach ($prompt in @($prompt10k, $prompt200k)) {
    $promptPath = Join-Path $repoRoot $prompt
    if (-not (Test-Path -LiteralPath $promptPath)) {
        throw "Prompt fixture not found at $promptPath"
    }
}

$modelFullPath = (Resolve-Path -LiteralPath $ModelPath).Path
$reasoning = if ($NoThinking) { "off" } else { "on" }

$args = @(
    "--model", $modelFullPath,
    "--alias", "ornith-1.0-35b-q4-k-m",
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
    "--reasoning", $reasoning
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

    $deadline = (Get-Date).AddMinutes($StartupTimeoutMinutes)
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
            if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
                $gpu = & nvidia-smi --query-gpu=memory.used,power.draw,temperature.gpu --format=csv,noheader,nounits --id=0
                Write-Host "Waiting for llama-server: GPU $gpu"
            } else {
                Write-Host "Waiting for llama-server..."
            }
            Start-Sleep -Seconds 10
        }
    }

    if (-not $ready) {
        throw "llama-server did not become ready. Check $errLog"
    }

    & $bench `
        -BaseUrl "http://127.0.0.1:$Port/v1" `
        -Model "ornith-1.0-35b-q4-k-m" `
        -CaseName "ornith-1.0-35b-q4-k-m-llamacpp-ctx256k-prompt10k-gen$MaxTokens" `
        -GpuIndex 0 `
        -MaxTokens $MaxTokens `
        -Runs $Runs `
        -WarmupRuns $WarmupRuns `
        -Temperature 0 `
        -Seed 1234 `
        -PromptFile $prompt10k `
        -PromptStyle BookContext `
        -TargetPromptTokens 10000

    if ($LASTEXITCODE -ne 0) {
        throw "10k benchmark failed with code $LASTEXITCODE"
    }

    & $bench `
        -BaseUrl "http://127.0.0.1:$Port/v1" `
        -Model "ornith-1.0-35b-q4-k-m" `
        -CaseName "ornith-1.0-35b-q4-k-m-llamacpp-ctx256k-prompt200k-gen$MaxTokens" `
        -GpuIndex 0 `
        -MaxTokens $MaxTokens `
        -Runs $Runs `
        -WarmupRuns $WarmupRuns `
        -Temperature 0 `
        -Seed 1234 `
        -PromptFile $prompt200k `
        -PromptStyle BookContext `
        -TargetPromptTokens 200000

    if ($LASTEXITCODE -ne 0) {
        throw "200k benchmark failed with code $LASTEXITCODE"
    }
} finally {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        Write-Host "Stopped llama-server PID $($process.Id)"
    }
}
