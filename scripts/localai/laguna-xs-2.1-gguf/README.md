# Poolside Laguna XS 2.1 Q4_K_M

This profile serves the original, unmodified `poolside/Laguna-XS-2.1-GGUF`
Q4_K_M file. It does not add or claim MTP. Poolside's OpenMDW-1.1 license and
model card are downloaded beside the GGUF.

Laguna support currently requires llama.cpp PR 25165. Run the included build,
download, and start scripts, then select `laguna-xs-2.1-q4-k-m` in Hermes under
the `Local 5090` provider. Direct endpoint: `http://127.0.0.1:39203/v1`.

## Fresh install for an agent

From the repository root, agents can use the validated catalog interface. The
first command only prints the plan; the second performs the download and build:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\localai\manage-model-profile.ps1 -Action Install -Model laguna
powershell -ExecutionPolicy Bypass -File scripts\localai\manage-model-profile.ps1 -Action Install -Model laguna -Execute
scripts\hermes\install-local-5090-provider.bat
powershell -ExecutionPolicy Bypass -File scripts\localai\manage-model-profile.ps1 -Action Start -Model laguna -Execute
```

The plain install downloads Poolside's original Q4_K_M GGUF and builds the
required Laguna-compatible llama.cpp runtime. It does not modify the model.

The benchmark wrapper defaults to the repository's standard 10k BookContext
fixture on the RTX 5090 profile.

## RTX 5090 baseline (no DFlash)

| Target | Actual prompt | Decode | Full request | Prompt eval |
| ---: | ---: | ---: | ---: | ---: |
| 10k | 9,379 | 136.25 tok/s | 106.603 tok/s | 1.763s |

This baseline does not use Poolside's separate DFlash drafter or KVFlash/SWA
cache optimizations.

## Optional Lucebox DFlash runtime

The complete fresh-install sequence is cataloged under `laguna-dflash`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\localai\manage-model-profile.ps1 -Action Install -Model laguna-dflash
powershell -ExecutionPolicy Bypass -File scripts\localai\manage-model-profile.ps1 -Action Install -Model laguna-dflash -Execute
powershell -ExecutionPolicy Bypass -File scripts\localai\manage-model-profile.ps1 -Action Start -Model laguna-dflash -Execute
powershell -ExecutionPolicy Bypass -File scripts\localai\manage-model-profile.ps1 -Action Benchmark -Model laguna-dflash -Execute
```

This downloads the Poolside target, Lucebox's separate DFlash drafter, and the
Qwen prefill drafter before building the Docker runtime. Docker Desktop with
NVIDIA GPU support is required.

Run `build-laguna-dflash-docker.ps1` once to compile the Linux SM120 server and
copy the three weights into a native Docker volume. Then
`start-laguna-xs-2.1-dflash-docker.ps1` serves the same unmodified Poolside
target with Lucebox's separate Laguna DFlash Q4 drafter and Qwen3-0.6B Q8
prefill drafter. It uses an 8,192-token
KVFlash resident pool, a 1,024-token chunk, a 2,048-token FA window, and port
`39204`. On this Windows host, the verified runtime is a local SM120 CUDA 13
Linux build stored in Docker volumes because the upstream Windows source uses
POSIX-only headers and the published image import did not complete.

The 2,048-token FA window is the benchmark-performance setting. Lucebox warns
that it drops old system/tool-definition attention at long context; start with
`-FaWindow 0` when using Hermes tool calls where full instruction visibility is
more important than the headline long-context decode rate.

`bench-laguna-xs-2.1-dflash.ps1` runs the checked-in deterministic code
completion fixtures `benchmarks/prompts/10k_DFLASH.txt` and
`benchmarks/prompts/200k_DFLASH.txt`. These prompts deliberately repeat code
structure so speculative acceptance can be measured; the BookContext fixture
is retained for general model comparisons but is not the DFlash A/B workload.

| Fixture | Plain full request / decode | DFlash full request / decode | Acceptance |
| ---: | ---: | ---: | ---: |
| 10k | 3.215s / 123.85 tok/s | 4.184s / 126.1 tok/s | 56.2% |
| 200k | 89.632s / 28.18 tok/s | 49.172s / 160.4 tok/s | 54.4% |
