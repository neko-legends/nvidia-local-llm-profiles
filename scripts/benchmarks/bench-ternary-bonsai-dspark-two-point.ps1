param([int]$Port = 39199, [int]$GpuIndex = 0)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$checkoutParent = Split-Path -Parent $repoRoot
$modelDir = Join-Path $checkoutParent ".local-model-cache\prism-ml\Ternary-Bonsai-27B-gguf"
$runtimeDir = if ($env:PRISM_LLAMA_DIR) { $env:PRISM_LLAMA_DIR } else { Join-Path $checkoutParent ".llama-runtimes\prism-62061f9-sm120-win-cuda12.8" }
$server = Join-Path $runtimeDir "llama-server.exe"
$model = Join-Path $modelDir "Ternary-Bonsai-27B-Q2_0.gguf"
$draft = Join-Path $modelDir "Ternary-Bonsai-27B-dspark-Q4_1.gguf"
$alias = "ternary-bonsai-27b-dspark-q4-1"

foreach ($path in @($server, $model, $draft)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required file not found: $path" }
}

function Invoke-BonsaiCase {
    param([int]$Target, [int]$ContextSize, [bool]$UseDspark, [string]$CasePrefix)

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outLog = Join-Path $repoRoot "logs\$CasePrefix-bench-server-$stamp.out.log"
    $errLog = Join-Path $repoRoot "logs\$CasePrefix-bench-server-$stamp.err.log"
    $serverArgs = @(
        "-m", $model, "--alias", $alias, "--host", "0.0.0.0", "--port", "$Port",
        "--device", "CUDA0", "-ngl", "999", "-fa", "on", "-c", "$ContextSize", "-np", "1",
        "--cache-type-k", "q4_0", "--cache-type-v", "q4_0", "--jinja", "--metrics", "--slots",
        "--reasoning-budget", "0", "--reasoning-format", "none"
    )
    if ($UseDspark) {
        $serverArgs += @(
            "-md", $draft, "--device-draft", "CUDA0", "-ngld", "999",
            "--cache-type-k-draft", "q4_0", "--cache-type-v-draft", "q4_0",
            "--spec-type", "draft-dspark", "--spec-draft-n-max", "4"
        )
    }

    $process = $null
    try {
        $process = Start-Process -FilePath $server -ArgumentList $serverArgs -WorkingDirectory $runtimeDir -RedirectStandardOutput $outLog -RedirectStandardError $errLog -WindowStyle Hidden -PassThru
        Write-Host "Started PID $($process.Id): target=$Target context=$ContextSize DSpark=$UseDspark"
        Write-Host "Server log: $errLog"
        $deadline = (Get-Date).AddMinutes(15)
        $ready = $false
        while ((Get-Date) -lt $deadline) {
            if ($process.HasExited) { throw "llama-server exited with code $($process.ExitCode). Check $errLog" }
            try { Invoke-RestMethod "http://127.0.0.1:$Port/v1/models" -TimeoutSec 4 | Out-Null; $ready = $true; break } catch { Start-Sleep 10 }
        }
        if (-not $ready) { throw "llama-server did not become ready. Check $errLog" }

        & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "bench-context-ladder.ps1") -BaseUrl "http://127.0.0.1:$Port/v1" -Model $alias -CasePrefix $CasePrefix -GpuIndex $GpuIndex -PromptTokenTargets $Target -MaxTokens 1024 -Runs 1 -WarmupRuns 0 -Temperature 0 -Seed 1234 -DisableThinking
        if ($LASTEXITCODE -ne 0) { throw "Benchmark target $Target failed with code $LASTEXITCODE" }
    } finally {
        if ($process -and -not $process.HasExited) { Stop-Process -Id $process.Id -Force }
        Start-Sleep 3
    }
}

Invoke-BonsaiCase -Target 10000 -ContextSize 16384 -UseDspark $true -CasePrefix "ternary-bonsai-27b-q2-0-dspark-q4-1-prism-b9591-ctx16k-n4-nothink"
Invoke-BonsaiCase -Target 10000 -ContextSize 262144 -UseDspark $false -CasePrefix "ternary-bonsai-27b-q2-0-target-only-prism-b9591-ctx262k-nothink"
Invoke-BonsaiCase -Target 200000 -ContextSize 262144 -UseDspark $false -CasePrefix "ternary-bonsai-27b-q2-0-target-only-prism-b9591-ctx262k-nothink"
