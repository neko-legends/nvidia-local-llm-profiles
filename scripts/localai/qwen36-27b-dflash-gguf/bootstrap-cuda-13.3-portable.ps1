$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$checkoutParent = (Resolve-Path (Join-Path $scriptDir "..\..\..\..")).Path
$runtimeRoot = Join-Path $checkoutParent ".llama-runtimes"
$downloadDir = Join-Path $runtimeRoot "downloads\cuda-13.3.1-redist"
$stageDir = Join-Path $runtimeRoot "cuda-13.3.1-redist-stage"
$cudaDir = Join-Path $runtimeRoot "cuda-13.3.1-portable"
$baseUrl = "https://developer.download.nvidia.com/compute/cuda/redist"

$packages = @(
    @{ Path = "cccl/windows-x86_64/cccl-windows-x86_64-13.3.3.4.1-archive.zip"; Sha256 = "48fab83097a636c4119da28bd3c9c9af9327e34c1efed17a14449cc2956ca6d1" },
    @{ Path = "cuda_crt/windows-x86_64/cuda_crt-windows-x86_64-13.3.73-archive.zip"; Sha256 = "9227ec7c80db10b7cb0d4ee71ed62ec7ae36e67890216413ab6f9afa35d577f0" },
    @{ Path = "cuda_cudart/windows-x86_64/cuda_cudart-windows-x86_64-13.3.29-archive.zip"; Sha256 = "1feb7dd266813ffe8dbc24e115183a5ac35a4795c8d34aca0df85ab616b64d9c" },
    @{ Path = "cuda_nvcc/windows-x86_64/cuda_nvcc-windows-x86_64-13.3.73-archive.zip"; Sha256 = "270214eaee58e49f8fca52a910a46afbfab227858e70897cba8afae10826280b" },
    @{ Path = "libcublas/windows-x86_64/libcublas-windows-x86_64-13.6.0.2-archive.zip"; Sha256 = "62e9fa30560c8f0a28e0cdcf9d6fc1fed347bcfab8847239b9ae1fdc1d86408a" },
    @{ Path = "libnvvm/windows-x86_64/libnvvm-windows-x86_64-13.3.73-archive.zip"; Sha256 = "ca8f11d5173ac16a166be8fafefbf9676542a097de1fce61b3f17696dffc1f27" }
)

New-Item -ItemType Directory -Force -Path $downloadDir, $stageDir, $cudaDir | Out-Null
foreach ($package in $packages) {
    $name = Split-Path $package.Path -Leaf
    $archive = Join-Path $downloadDir $name
    if (-not (Test-Path $archive)) {
        Invoke-WebRequest "$baseUrl/$($package.Path)" -OutFile $archive
    }
    $actual = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $package.Sha256) { throw "SHA-256 mismatch for $name" }

    $expanded = Join-Path $stageDir ([IO.Path]::GetFileNameWithoutExtension($name))
    if (-not (Test-Path $expanded)) { Expand-Archive $archive $expanded }
    $root = Get-ChildItem $expanded -Directory | Select-Object -First 1
    if (-not $root) { throw "Unexpected archive layout for $name" }
    Copy-Item (Join-Path $root.FullName "*") $cudaDir -Recurse -Force
}

& (Join-Path $cudaDir "bin\nvcc.exe") --version
Write-Host "Portable CUDA 13.3 toolkit ready at $cudaDir" -ForegroundColor Green
