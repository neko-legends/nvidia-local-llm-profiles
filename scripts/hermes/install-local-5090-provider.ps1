param(
  [string]$ProviderName = "Local 5090",
  [int]$RouterPort = 39190,
  [string]$QwopusBaseUrl = "http://127.0.0.1:39182/v1",
  [string]$Qwopus35BaseUrl = "http://127.0.0.1:39191/v1",
  [string]$Qwopus35Q4BaseUrl = "http://127.0.0.1:39193/v1",
  [string]$DiffusionGemmaBaseUrl = "http://127.0.0.1:8890/v1",
  [string]$OrnithBaseUrl = "http://127.0.0.1:39188/v1",
  [string]$OrnithQ5BaseUrl = "http://127.0.0.1:39189/v1",
  [string]$AeonOrnithNvfp4BaseUrl = "http://127.0.0.1:39187/v1",
  [string]$Qwen36_27bNvfp4BaseUrl = "http://127.0.0.1:39195/v1",
  [switch]$NoStartRouter
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")
$HermesDir = Join-Path $env:LOCALAPPDATA "hermes"
$ConfigPath = Join-Path $HermesDir "config.yaml"
$RouterDir = Join-Path $HermesDir "local-5090-router"
$RouterSource = Join-Path $ScriptDir "local-5090-router.py"
$RouterTarget = Join-Path $RouterDir "local-5090-router.py"
$ConfigureScript = Join-Path $ScriptDir "configure-hermes-local-5090.py"

if (-not (Test-Path $HermesDir)) {
  New-Item -ItemType Directory -Path $HermesDir | Out-Null
}

if (-not (Test-Path $ConfigPath)) {
  "custom_providers: []" | Set-Content -Path $ConfigPath -Encoding UTF8
}

New-Item -ItemType Directory -Path $RouterDir -Force | Out-Null
Copy-Item -Path $RouterSource -Destination $RouterTarget -Force

$PythonCandidates = @(
  (Join-Path $HermesDir ".venv\Scripts\python.exe"),
  (Join-Path $HermesDir "hermes-agent\.venv\Scripts\python.exe"),
  (Join-Path $env:LOCALAPPDATA "Programs\Python\Python312\python.exe"),
  (Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe"),
  "python"
)

$Python = $null
foreach ($Candidate in $PythonCandidates) {
  $ResolvedPython = $null
  try {
    $Command = Get-Command $Candidate -ErrorAction Stop
    $ResolvedPython = $Command.Source
  } catch {
    if (Test-Path $Candidate) {
      $ResolvedPython = $Candidate
    }
  }

  if ($ResolvedPython) {
    & $ResolvedPython -c "import yaml" 2>$null
    if ($LASTEXITCODE -eq 0) {
      $Python = $ResolvedPython
      break
    }
  }
}

if (-not $Python) {
  throw "Python with PyYAML was not found. Install PyYAML with 'pip install pyyaml' or run from Hermes' Python environment."
}

& $Python $ConfigureScript `
  --config $ConfigPath `
  --provider-name $ProviderName `
  --router-port $RouterPort `
  --qwopus-base-url $QwopusBaseUrl `
  --qwopus35-base-url $Qwopus35BaseUrl `
  --diffusiongemma-base-url $DiffusionGemmaBaseUrl `
  --ornith-base-url $OrnithBaseUrl `
  --ornith-q5-base-url $OrnithQ5BaseUrl `
  --aeon-ornith-nvfp4-base-url $AeonOrnithNvfp4BaseUrl `
  --qwen36-27b-nvfp4-base-url $Qwen36_27bNvfp4BaseUrl

if (-not $NoStartRouter) {
  $OutLog = Join-Path $RouterDir "local-5090-router.out.log"
  $ErrLog = Join-Path $RouterDir "local-5090-router.err.log"

  $Existing = Get-NetTCPConnection -LocalPort $RouterPort -State Listen -ErrorAction SilentlyContinue
  if (-not $Existing) {
    Start-Process -FilePath $Python `
      -ArgumentList @(
        $RouterTarget,
        "--port", "$RouterPort",
        "--qwopus-base-url", $QwopusBaseUrl,
        "--qwopus35-base-url", $Qwopus35BaseUrl,
        "--qwopus35-q4-base-url", $Qwopus35Q4BaseUrl,
        "--diffusiongemma-base-url", $DiffusionGemmaBaseUrl,
        "--ornith-base-url", $OrnithBaseUrl,
        "--ornith-q5-base-url", $OrnithQ5BaseUrl,
        "--aeon-ornith-nvfp4-base-url", $AeonOrnithNvfp4BaseUrl,
        "--qwen36-27b-nvfp4-base-url", $Qwen36_27bNvfp4BaseUrl
      ) `
      -WorkingDirectory $RouterDir `
      -RedirectStandardOutput $OutLog `
      -RedirectStandardError $ErrLog `
      -WindowStyle Hidden
  } else {
    Write-Warning "Router is already listening on port $RouterPort. Restart it to load newly added model routes."
  }
}

Write-Host ""
Write-Host "Hermes provider '$ProviderName' is configured."
Write-Host "Router: http://127.0.0.1:$RouterPort/v1"
Write-Host "Models:"
Write-Host "  - qwopus3.6-27b-coder-mtp-q5-k-m -> $QwopusBaseUrl"
Write-Host "  - qwopus3.6-35b-a3b-coder-mtp-q5-k-m -> $Qwopus35BaseUrl"
Write-Host "  - qwopus3.6-35b-a3b-coder-mtp-q4-k-m -> $Qwopus35Q4BaseUrl"
Write-Host "  - diffusiongemma -> $DiffusionGemmaBaseUrl"
Write-Host "  - ornith-1.0-35b-q4-k-m -> $OrnithBaseUrl"
Write-Host "  - ornith-1.0-35b-q5-k-m -> $OrnithQ5BaseUrl"
Write-Host "  - aeon-ornith-1.0-35b-nvfp4 -> $AeonOrnithNvfp4BaseUrl"
Write-Host "  - qwen36-27b-nvfp4-mtp-gguf -> $Qwen36_27bNvfp4BaseUrl"
Write-Host ""
Write-Host "Restart Hermes Desktop, then open the model menu and choose '$ProviderName'."
Write-Host "Start the model servers separately before using them."
