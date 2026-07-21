[CmdletBinding()]
param(
    [ValidateSet("List", "Show", "Install", "Start", "Benchmark", "Validate")]
    [string]$Action = "List",
    [string]$Model,
    [switch]$Execute,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\..")).Path
$catalogPath = Join-Path $PSScriptRoot "model-profiles.json"
$catalog = Get-Content -Raw -LiteralPath $catalogPath | ConvertFrom-Json

function Get-AbsolutePath([string]$relativePath) {
    return [IO.Path]::GetFullPath((Join-Path $repoRoot $relativePath))
}

function Test-Catalog {
    $errors = [Collections.Generic.List[string]]::new()
    $keys = @{}
    if ($catalog.schemaVersion -ne 1) { $errors.Add("Unsupported schemaVersion: $($catalog.schemaVersion)") }
    foreach ($profile in $catalog.profiles) {
        foreach ($required in @("id", "name", "profileDir", "endpoint", "modelAlias", "start")) {
            if (-not $profile.$required) { $errors.Add("Profile '$($profile.id)' is missing '$required'.") }
        }
        foreach ($key in @($profile.id) + @($profile.aliases)) {
            $normalized = $key.ToLowerInvariant()
            if ($keys.ContainsKey($normalized)) { $errors.Add("Duplicate id/alias '$key' in '$($profile.id)' and '$($keys[$normalized])'.") }
            else { $keys[$normalized] = $profile.id }
        }
        foreach ($relative in @($profile.profileDir, $profile.start, $profile.benchmark) + @($profile.install | ForEach-Object path)) {
            if ($relative -and -not (Test-Path -LiteralPath (Get-AbsolutePath $relative))) {
                $errors.Add("Profile '$($profile.id)' references missing path '$relative'.")
            }
        }
        if ($profile.endpoint -notmatch '^http://127\.0\.0\.1:\d+/v1$') { $errors.Add("Profile '$($profile.id)' has an invalid local endpoint.") }
        if ($profile.modelAlias -ne $profile.id) { $errors.Add("Profile '$($profile.id)' modelAlias must equal its canonical id.") }
    }
    if (-not (Test-Path -LiteralPath (Get-AbsolutePath $catalog.sharedHermesInstaller))) {
        $errors.Add("Shared Hermes installer is missing: $($catalog.sharedHermesInstaller)")
    }
    if ($errors.Count) { throw ($errors -join [Environment]::NewLine) }
    return [pscustomobject]@{ valid = $true; profileCount = @($catalog.profiles).Count; catalog = $catalogPath }
}

function Resolve-Profile([string]$name) {
    if (-not $name) { throw "-Model is required for action $Action. Run -Action List to see valid IDs." }
    $match = @($catalog.profiles | Where-Object {
        $_.id -ieq $name -or @($_.aliases | Where-Object { $_ -ieq $name }).Count -gt 0
    })
    if ($match.Count -ne 1) { throw "Unknown model '$name'. Run -Action List; model names are never guessed." }
    return $match[0]
}

function Invoke-ProfileScript([string]$relativePath) {
    $path = Get-AbsolutePath $relativePath
    $workingDir = Split-Path -Parent $path
    Push-Location $workingDir
    try {
        if ([IO.Path]::GetExtension($path) -ieq ".bat") {
            & "$env:ComSpec" /d /c "call `"$path`" <nul"
        } elseif ([IO.Path]::GetExtension($path) -ieq ".ps1") {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
        } else { throw "Unsupported script type: $path" }
        if ($LASTEXITCODE -ne 0) { throw "Script failed with exit code $LASTEXITCODE`: $relativePath" }
    } finally { Pop-Location }
}

$validation = Test-Catalog
if ($Action -eq "Validate") {
    if ($Json) { $validation | ConvertTo-Json -Depth 5 } else { Write-Host "Catalog valid: $($validation.profileCount) installable profiles." -ForegroundColor Green }
    exit 0
}

if ($Action -eq "List") {
    $rows = @($catalog.profiles | ForEach-Object {
        [pscustomobject]@{ id = $_.id; name = $_.name; endpoint = $_.endpoint; aliases = @($_.aliases) }
    })
    if ($Json) { $rows | ConvertTo-Json -Depth 5 } else { $rows | Format-Table id, name, endpoint -AutoSize }
    exit 0
}

$profile = Resolve-Profile $Model
if ($Action -eq "Show") {
    if ($Json) { $profile | ConvertTo-Json -Depth 8 } else { $profile | Format-List }
    exit 0
}

$scripts = switch ($Action) {
    "Install" { @($profile.install) }
    "Start" { @([pscustomobject]@{ path = $profile.start }) }
    "Benchmark" {
        if (-not $profile.benchmark) { throw "No automated benchmark is cataloged for '$($profile.id)'. See its profile notes." }
        @([pscustomobject]@{ path = $profile.benchmark })
    }
}
$plan = @($scripts | ForEach-Object {
    [pscustomobject]@{ path = $_.path; requires = @($_.requires | Where-Object { $_ }); absolutePath = Get-AbsolutePath $_.path }
})

if (-not $Execute) {
    $result = [pscustomobject]@{
        execute = $false
        action = $Action
        model = $profile.id
        endpoint = $profile.endpoint
        modelAlias = $profile.modelAlias
        scripts = $plan
        hint = "Review the plan, then repeat with -Execute to run it. Install Hermes once with $($catalog.sharedHermesInstaller)."
    }
    if ($Json) { $result | ConvertTo-Json -Depth 8 } else { $result | Format-List; $plan | Format-Table path, requires -AutoSize }
    exit 0
}

foreach ($step in $scripts) {
    foreach ($variable in @($step.requires | Where-Object { $_ })) {
        if (-not [Environment]::GetEnvironmentVariable($variable)) { throw "'$($profile.id)' requires environment variable $variable before running $($step.path)." }
    }
    Write-Host "$Action [$($profile.id)]: $($step.path)" -ForegroundColor Cyan
    Invoke-ProfileScript $step.path
}
