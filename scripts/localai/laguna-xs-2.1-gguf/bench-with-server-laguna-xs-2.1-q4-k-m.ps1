param(
    [string]$ModelPath = "",
    [string]$LlamaDir = "",
    [int]$Port = 39203,
    [int]$GpuIndex = 0,
    [int]$ContextSize = 210000,
    [int[]]$PromptTokenTargets = @(10000),
    [int]$MaxTokens = 1024
)
$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$checkoutParent = Split-Path -Parent $repoRoot
$bench = Join-Path $repoRoot "scripts\benchmarks\bench-context-ladder.ps1"
if (-not $ModelPath) { $ModelPath = Join-Path $checkoutParent ".local-model-cache\poolside\Laguna-XS-2.1-GGUF\Laguna-XS-2.1-Q4_K_M.gguf" }
if (-not $LlamaDir) { $LlamaDir = Join-Path $checkoutParent ".llama-runtimes\laguna-llama-src\build-sm120-ninja\bin" }
$server = Join-Path $LlamaDir "llama-server.exe"
foreach ($path in @($ModelPath,$server,$bench)) { if (-not (Test-Path -LiteralPath $path)) { throw "Missing: $path" } }
$alias = "laguna-xs-2.1-q4-k-m"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = Join-Path $repoRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$outLog = Join-Path $logDir "laguna-xs-2.1-q4-bench-server-$stamp.out.log"
$errLog = Join-Path $logDir "laguna-xs-2.1-q4-bench-server-$stamp.err.log"
$args = @("--model",(Resolve-Path -LiteralPath $ModelPath).Path,"--alias",$alias,"--host","127.0.0.1","--port","$Port","--device","CUDA0","--gpu-layers","all","--ctx-size","$ContextSize","--cache-type-k","q4_0","--cache-type-v","q4_0","--flash-attn","on","--parallel","1","--cont-batching","--jinja","--metrics","--slots","--reasoning","off")
$process = $null
try {
    $process = Start-Process -FilePath $server -ArgumentList $args -WorkingDirectory $LlamaDir -RedirectStandardOutput $outLog -RedirectStandardError $errLog -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddMinutes(15); $ready = $false
    do {
        if ($process.HasExited) { throw "llama-server exited; see $errLog" }
        try { Invoke-RestMethod "http://127.0.0.1:$Port/v1/models" -TimeoutSec 4 | Out-Null; $ready=$true } catch { Start-Sleep 10 }
    } until ($ready -or (Get-Date) -ge $deadline)
    if (-not $ready) { throw "llama-server did not become ready; see $errLog" }
    foreach ($target in $PromptTokenTargets) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $bench -BaseUrl "http://127.0.0.1:$Port/v1" -Model $alias -CasePrefix "laguna-xs-2.1-q4-k-m" -GpuIndex $GpuIndex -PromptTokenTargets $target -MaxTokens $MaxTokens -Runs 1 -WarmupRuns 0 -Temperature 0 -Seed 1234 -DisableThinking
        if ($LASTEXITCODE -ne 0) { throw "Benchmark target $target failed" }
    }
} finally { if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force } }
