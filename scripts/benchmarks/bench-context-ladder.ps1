param(
    [string]$BaseUrl = "http://127.0.0.1:39182/v1",
    [string]$Model = "qwopus3.6-27b-coder-mtp-q5-k-m",
    [string]$CasePrefix = "qwopus-coder-mtp-q5",
    [int]$GpuIndex = 0,
    [int[]]$PromptTokenTargets = @(8192, 32768, 65536, 131072, 200000),
    [int]$MaxTokens = 1024,
    [int]$Runs = 3,
    [int]$WarmupRuns = 0,
    [double]$Temperature = 0.0,
    [int]$Seed = 1234,
    [ValidateSet("BookContext", "CodeContext")]
    [string]$PromptStyle = "BookContext",
    [switch]$DisableThinking
)

$ErrorActionPreference = "Stop"

$bench = Join-Path $PSScriptRoot "bench-openai-chat-endpoint.ps1"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$summaryCsv = Join-Path $repoRoot ("results\rtx-5090\{0}-context-ladder-summary-{1}.csv" -f $CasePrefix, $stamp)
$summaryRows = @()

function Save-LadderSummary {
    param(
        [object[]]$Rows,
        [string]$Path
    )

    $summaryDir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $summaryDir)) {
        New-Item -ItemType Directory -Force -Path $summaryDir | Out-Null
    }

    $Rows | Export-Csv -LiteralPath $Path -NoTypeInformation
}

foreach ($target in $PromptTokenTargets) {
    $caseName = "{0}-prompt{1}k-gen{2}" -f $CasePrefix, ([math]::Round($target / 1000)), $MaxTokens
    $outCsv = Join-Path $repoRoot ("results\rtx-5090\{0}-{1}.csv" -f $caseName, $stamp)
    $contextStartedAt = Get-Date
    $contextTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $summaryRow = [pscustomobject]@{
        case = $caseName
        base_url = $BaseUrl
        model = $Model
        gpu_index = $GpuIndex
        target_prompt_tokens = $target
        actual_prompt_tokens_max = $null
        max_tokens = $MaxTokens
        runs = $Runs
        warmup_runs = $WarmupRuns
        status = "running"
        exit_code = $null
        context_started_at = $contextStartedAt.ToString("o")
        context_ended_at = ""
        context_elapsed_seconds = $null
        avg_wall_completion_tps = $null
        result_csv = $outCsv
    }
    $summaryRows += $summaryRow
    Save-LadderSummary -Rows $summaryRows -Path $summaryCsv

    Write-Host ""
    Write-Host "Context ladder target: $target prompt tokens" -ForegroundColor Cyan
    Write-Host "Context started: $($contextStartedAt.ToString('o'))"

    $benchArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $bench,
        "-BaseUrl", $BaseUrl,
        "-Model", $Model,
        "-CaseName", $caseName,
        "-GpuIndex", "$GpuIndex",
        "-MaxTokens", "$MaxTokens",
        "-Runs", "$Runs",
        "-WarmupRuns", "$WarmupRuns",
        "-Temperature", "$Temperature",
        "-Seed", "$Seed",
        "-PromptStyle", $PromptStyle,
        "-TargetPromptTokens", "$target",
        "-OutCsv", $outCsv
    )
    if ($DisableThinking) {
        $benchArgs += "-DisableThinking"
    }

    & powershell @benchArgs
    $exitCode = $LASTEXITCODE

    $contextTimer.Stop()
    $contextEndedAt = Get-Date
    Write-Host "Context ended:   $($contextEndedAt.ToString('o'))"

    $measuredRows = @()
    if (Test-Path -LiteralPath $outCsv) {
        $measuredRows = @(Import-Csv -LiteralPath $outCsv | Where-Object { $_.warmup -ne "True" })
    }

    $avgTps = $null
    $actualPromptTokens = $null
    if ($measuredRows.Count -gt 0) {
        $avgTps = [math]::Round((($measuredRows | ForEach-Object { [double]$_.wall_completion_tps }) | Measure-Object -Average).Average, 3)
        $actualPromptTokens = (($measuredRows | ForEach-Object { [int]$_.prompt_tokens }) | Measure-Object -Maximum).Maximum
    }

    $summaryRow.actual_prompt_tokens_max = $actualPromptTokens
    $summaryRow.status = if ($exitCode -eq 0) { "ok" } else { "failed" }
    $summaryRow.exit_code = $exitCode
    $summaryRow.context_ended_at = $contextEndedAt.ToString("o")
    $summaryRow.context_elapsed_seconds = [math]::Round($contextTimer.Elapsed.TotalSeconds, 3)
    $summaryRow.avg_wall_completion_tps = $avgTps
    Save-LadderSummary -Rows $summaryRows -Path $summaryCsv

    if ($exitCode -ne 0) {
        Write-Warning "Context target $target exited with code $exitCode. Continuing so the summary captures later targets too."
    }
}

Save-LadderSummary -Rows $summaryRows -Path $summaryCsv
Write-Host ""
Write-Host "Wrote context ladder summary: $summaryCsv" -ForegroundColor Green
