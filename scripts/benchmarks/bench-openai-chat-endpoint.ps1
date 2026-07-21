param(
    [string]$BaseUrl = "http://127.0.0.1:39182/v1",
    [string]$Model = "qwopus3.6-27b-coder-mtp-q5-k-m",
    [string]$CaseName = "local-openai-endpoint",
    [int]$GpuIndex = 0,
    [int]$MaxTokens = 512,
    [int]$Runs = 3,
    [int]$WarmupRuns = 1,
    [double]$Temperature = 0.0,
    [int]$Seed = 1234,
    [string]$OutCsv = "",
    [string]$Prompt = "",
    [string]$PromptFile = "",
    [string]$PromptOutFile = "",
    [switch]$PromptOnly,
    [switch]$DisableThinking,
    [int]$TargetPromptTokens = 0,
    [ValidateSet("Default", "BookContext", "CodeContext")]
    [string]$PromptStyle = "Default"
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
}

function New-BookBenchmarkPrompt {
    param([int]$TargetTokens)

    if ($TargetTokens -le 0) {
        $TargetTokens = 8192
    }

    $targetChars = [math]::Max(2000, [int]($TargetTokens * 4.2))
    $builder = [System.Text.StringBuilder]::new()

    [void]$builder.AppendLine("You are writing a continuity-heavy technical novel benchmark.")
    [void]$builder.AppendLine("Use every relevant detail from the project bible below. Preserve names, constraints, timelines, and engineering rules.")
    [void]$builder.AppendLine("After the bible, write a polished chapter outline and then draft the opening scene. Do not summarize the bible first.")
    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("PROJECT BIBLE")

    $section = 1
    while ($builder.Length -lt $targetChars) {
        [void]$builder.AppendLine("")
        [void]$builder.AppendLine(("Section {0:00000}: Continuity Packet" -f $section))
        [void]$builder.AppendLine(("Location: Node-{0:00000}, a workshop beside a cooling tower, a diagnostics bench, and a wall of handwritten benchmark results." -f $section))
        [void]$builder.AppendLine(("Characters: Mira keeps exact telemetry logs; Sol repairs inference rigs; Jae validates every claim against raw traces; Nox edits the final manuscript for contradictions." -f $section))
        [void]$builder.AppendLine(("Constraint: The chapter must remember that Packet {0:00000} links thermal stability, token throughput, and a disputed power curve without treating any one metric as the whole truth." -f $section))
        [void]$builder.AppendLine(("Timeline: At T+{0} minutes the team compares a short-context success against a long-context regression, then decides whether the result is real or measurement noise." -f (($section * 7) % 1440)))
        [void]$builder.AppendLine(("Artifact: Ledger entry {0:00000} records prompt pressure, generated-token speed, first-token delay, GPU clock, memory pressure, and whether the local endpoint stayed responsive." -f $section))
        [void]$builder.AppendLine(("Style rule: Mention the artifact naturally if this packet becomes relevant; avoid dumping raw lists unless a character is reading a log aloud." -f $section))
        [void]$builder.AppendLine(("Callback: A small detail from Packet {0:00000} should matter later: a blue status LED blinks twice whenever a benchmark completes without throttling." -f $section))
        [void]$builder.AppendLine("Narrative tension: The team wants maximum speed, but only if the configuration remains reproducible for future agents reading the repository.")
        $section++
    }

    [void]$builder.AppendLine("")
    [void]$builder.AppendLine("TASK")
    [void]$builder.AppendLine("Write a chapter outline, then draft the opening scene in a grounded technical-fiction style. Use the continuity bible when useful, but keep the prose readable.")
    [void]$builder.AppendLine("Return original prose only.")

    $builder.ToString()
}

function New-CodeBenchmarkPrompt {
    param([int]$TargetTokens)

    if ($TargetTokens -le 0) { $TargetTokens = 8192 }
    # Laguna's tokenizer averages about 3.15 characters/token on this repeated
    # TypeScript workload (measured at both 10k and 200k scales).
    $targetChars = [math]::Max(2000, [int]($TargetTokens * 3.14))
    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine("You are completing a TypeScript repository. Study the modules below, preserve their conventions, and implement the requested final module. Return code only.")
    [void]$builder.AppendLine("")

    $module = 1
    while ($builder.Length -lt $targetChars) {
        $name = "packet{0:00000}" -f $module
        $next = "packet{0:00000}" -f ($module + 1)
        $factor = ($module % 17) + 3
        [void]$builder.AppendLine(("// src/pipeline/{0}.ts" -f $name))
        [void]$builder.AppendLine("export interface Packet { id: number; label: string; values: readonly number[]; }")
        [void]$builder.AppendLine(("export const {0} = (packet: Packet): Packet => ({{" -f $name))
        [void]$builder.AppendLine("  ...packet,")
        [void]$builder.AppendLine(("  label: `${{packet.label}}:{0}`," -f $name))
        [void]$builder.AppendLine(("  values: packet.values.map((value, index) => (value + index + {0}) % 65521)," -f $factor))
        [void]$builder.AppendLine("});")
        [void]$builder.AppendLine(("export const validate{0} = (packet: Packet): boolean =>" -f $module))
        [void]$builder.AppendLine("  packet.id >= 0 && packet.label.length > 0 && packet.values.every(Number.isFinite);")
        [void]$builder.AppendLine(("// The next stage is {0}; keep transforms immutable and deterministic." -f $next))
        [void]$builder.AppendLine("")
        $module++
    }

    [void]$builder.AppendLine("// TASK")
    [void]$builder.AppendLine(("// Implement src/pipeline/packet{0:00000}.ts using the exact repository conventions above." -f $module))
    [void]$builder.AppendLine("// Include the Packet interface, immutable transform, validator, and next-stage comment. Return TypeScript code only.")
    $builder.ToString()
}

function Get-Sha256 {
    param([string]$Text)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        (($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    } finally {
        $sha.Dispose()
    }
}

if ($Prompt -and $PromptFile) {
    throw "Use either -Prompt or -PromptFile, not both."
}

if ($PromptFile) {
    $promptFileFull = if ([System.IO.Path]::IsPathRooted($PromptFile)) {
        [System.IO.Path]::GetFullPath($PromptFile)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path (Get-RepoRoot) $PromptFile))
    }

    if (-not (Test-Path -LiteralPath $promptFileFull)) {
        throw "Prompt file not found at $promptFileFull"
    }

    $Prompt = [System.IO.File]::ReadAllText($promptFileFull, [System.Text.Encoding]::UTF8)
}

if (-not $Prompt) {
    if ($PromptStyle -eq "CodeContext") {
        $Prompt = New-CodeBenchmarkPrompt -TargetTokens $TargetPromptTokens
    } elseif ($PromptStyle -eq "BookContext" -or $TargetPromptTokens -gt 0) {
        $Prompt = New-BookBenchmarkPrompt -TargetTokens $TargetPromptTokens
        $PromptStyle = "BookContext"
    } else {
        $Prompt = @"
Write a compact but realistic PowerShell module that watches a project folder for new .log files, keeps only the newest five logs per subfolder, and prints a short JSON summary. Include helper functions, validation, and comments where useful. Return code only.
"@
    }
}

$promptHash = Get-Sha256 -Text $Prompt

if ($PromptOutFile) {
    $promptOutFull = if ([System.IO.Path]::IsPathRooted($PromptOutFile)) {
        [System.IO.Path]::GetFullPath($PromptOutFile)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path (Get-RepoRoot) $PromptOutFile))
    }

    $promptOutDir = Split-Path -Parent $promptOutFull
    if (-not (Test-Path -LiteralPath $promptOutDir)) {
        New-Item -ItemType Directory -Force -Path $promptOutDir | Out-Null
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($promptOutFull, $Prompt, $utf8NoBom)
    Write-Host "Wrote prompt file: $promptOutFull" -ForegroundColor Green
    Write-Host "Prompt SHA256: $promptHash"
}

if ($PromptOnly) {
    Write-Host "Prompt style: $PromptStyle"
    Write-Host "Prompt target tokens: $TargetPromptTokens"
    Write-Host "Prompt chars: $($Prompt.Length)"
    Write-Host "Prompt SHA256: $promptHash"
    return
}

function Get-GpuSnapshot {
    param([int]$Index)

    if (-not (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{
            index = $Index
            name = ""
            driver = ""
            power_w = $null
            clock_mhz = $null
            mem_clock_mhz = $null
            temp_c = $null
            memory_used_mib = $null
            memory_total_mib = $null
        }
    }

    $query = "index,name,driver_version,power.draw,clocks.gr,clocks.mem,temperature.gpu,memory.used,memory.total"
    $line = & nvidia-smi --id=$Index --query-gpu=$query --format=csv,noheader,nounits
    $parts = @($line -split "," | ForEach-Object { $_.Trim() })

    [pscustomobject]@{
        index = [int]$parts[0]
        name = $parts[1]
        driver = $parts[2]
        power_w = [double]$parts[3]
        clock_mhz = [int]$parts[4]
        mem_clock_mhz = [int]$parts[5]
        temp_c = [int]$parts[6]
        memory_used_mib = [int]$parts[7]
        memory_total_mib = [int]$parts[8]
    }
}

function Invoke-ChatRun {
    param(
        [int]$RunNumber,
        [bool]$Warmup
    )

    $before = Get-GpuSnapshot -Index $GpuIndex
    $bodyObject = @{
        model = $Model
        messages = @(@{ role = "user"; content = $Prompt })
        max_tokens = $MaxTokens
        temperature = $Temperature
        seed = $Seed
        stream = $false
    }
    if ($DisableThinking) {
        $bodyObject.chat_template_kwargs = @{ enable_thinking = $false }
    }
    $body = $bodyObject | ConvertTo-Json -Depth 10

    $startedAt = Get-Date
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = Invoke-RestMethod `
        -Uri "$BaseUrl/chat/completions" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -TimeoutSec 1200
    $watch.Stop()
    $endedAt = Get-Date
    $after = Get-GpuSnapshot -Index $GpuIndex

    $completionTokens = 0
    $promptTokens = 0
    $totalTokens = 0
    if ($response.usage) {
        $completionTokens = [int]$response.usage.completion_tokens
        $promptTokens = [int]$response.usage.prompt_tokens
        $totalTokens = [int]$response.usage.total_tokens
    }

    [pscustomobject]@{
        timestamp = $startedAt.ToString("s")
        started_at = $startedAt.ToString("o")
        ended_at = $endedAt.ToString("o")
        case = $CaseName
        warmup = $Warmup
        run = $RunNumber
        base_url = $BaseUrl
        model = $Model
        gpu_index = $GpuIndex
        gpu_name = $before.name
        driver = $before.driver
        max_tokens = $MaxTokens
        temperature = $Temperature
        seed = $Seed
        prompt_style = $PromptStyle
        target_prompt_tokens = $TargetPromptTokens
        prompt_chars = $Prompt.Length
        prompt_sha256 = $promptHash
        prompt_tokens = $promptTokens
        completion_tokens = $completionTokens
        total_tokens = $totalTokens
        wall_seconds = [math]::Round($watch.Elapsed.TotalSeconds, 3)
        wall_completion_tps = if ($watch.Elapsed.TotalSeconds -gt 0) { [math]::Round($completionTokens / $watch.Elapsed.TotalSeconds, 3) } else { 0 }
        power_before_w = $before.power_w
        power_after_w = $after.power_w
        clock_before_mhz = $before.clock_mhz
        clock_after_mhz = $after.clock_mhz
        mem_clock_before_mhz = $before.mem_clock_mhz
        mem_clock_after_mhz = $after.mem_clock_mhz
        temp_before_c = $before.temp_c
        temp_after_c = $after.temp_c
        memory_before_mib = $before.memory_used_mib
        memory_after_mib = $after.memory_used_mib
        memory_total_mib = $before.memory_total_mib
    }
}

$repoRoot = Get-RepoRoot
if (-not $OutCsv) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutCsv = Join-Path $repoRoot "results\rtx-5090\$CaseName-$stamp.csv"
}

Write-Host "Benchmarking $Model at $BaseUrl" -ForegroundColor Cyan
Write-Host "GPU index: $GpuIndex"
Write-Host "Prompt:    $PromptStyle, target tokens $TargetPromptTokens, chars $($Prompt.Length)"
Write-Host "Output:    $OutCsv"

$rows = @()
for ($i = 1; $i -le $WarmupRuns; $i++) {
    Write-Host "Warmup $i of $WarmupRuns"
    $rows += Invoke-ChatRun -RunNumber $i -Warmup $true
}

for ($i = 1; $i -le $Runs; $i++) {
    Write-Host "Measured run $i of $Runs"
    $rows += Invoke-ChatRun -RunNumber $i -Warmup $false
}

$outDir = Split-Path -Parent $OutCsv
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation
$rows | Where-Object { -not $_.warmup } | Format-Table run,completion_tokens,wall_seconds,wall_completion_tps,power_after_w,temp_after_c,clock_after_mhz -AutoSize
Write-Host "Wrote $OutCsv" -ForegroundColor Green
