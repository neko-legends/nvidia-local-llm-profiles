param(
    [string]$BaseUrl = "http://127.0.0.1:39204/v1",
    [int[]]$PromptTokenTargets = @(10000, 200000),
    [int]$MaxTokens = 1024,
    [int]$GpuIndex = 0
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..\..")).Path
$bench = Join-Path $repoRoot "scripts\benchmarks\bench-openai-chat-endpoint.ps1"
$model = "laguna-xs-2.1-q4-k-m-dflash"

foreach ($target in $PromptTokenTargets) {
    $promptFile = Join-Path $repoRoot ("benchmarks\prompts\{0}_DFLASH.txt" -f ($(if ($target -eq 10000) { "10k" } elseif ($target -eq 200000) { "200k" } else { throw "No checked-in DFlash prompt for $target tokens." })))
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outCsv = Join-Path $repoRoot ("results\rtx-5090\laguna-xs-2.1-q4-k-m-dflash-prompt{0}-gen{1}-{2}.csv" -f $target, $MaxTokens, $stamp)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bench `
        -BaseUrl $BaseUrl `
        -Model $model `
        -CaseName ("laguna-xs-2.1-q4-k-m-dflash-prompt{0}-gen{1}" -f $target, $MaxTokens) `
        -GpuIndex $GpuIndex `
        -MaxTokens $MaxTokens `
        -Runs 1 `
        -WarmupRuns 0 `
        -Temperature 0 `
        -Seed 1234 `
        -PromptFile $promptFile `
        -PromptStyle CodeContext `
        -TargetPromptTokens $target `
        -OutCsv $outCsv `
        -DisableThinking
    if ($LASTEXITCODE -ne 0) { throw "DFlash benchmark failed for target $target." }
}
