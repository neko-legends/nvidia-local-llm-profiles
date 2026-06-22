# RTX 5090 Benchmark Plan

Goal: give future agents enough measured numbers and exact settings to choose the fastest stable local model profile for Hermes and LocalAI on the RTX 5090.

## Priority Order

1. Qwopus3.6 Coder MTP GGUF on llama.cpp CUDA.
2. Qwen3.6 Text NVFP4 MTP on vLLM Docker.
3. RTX 3090 comparisons only after the RTX 5090 profile has stable numbers.

## Required Environment State

- RTX 5090 is GPU `0`.
- MSI Afterburner voltage/frequency curve is applied.
- Driver is recorded from `nvidia-smi`.
- Model payloads live in `D:\Tools\LocalAI\models`.
- Results are written under `results/rtx-5090/`.

## Metrics To Record

Each row should include:

- GPU index and GPU name.
- Driver version.
- Model id and model file/repo.
- Runtime: llama.cpp CUDA or vLLM Docker.
- Endpoint base URL.
- Context length.
- KV cache type.
- Speculative decoding settings.
- Prompt style, prompt-token target, and prompt text hash.
- Prompt tokens, completion tokens, total tokens.
- Wall-clock tokens per second.
- Request start and end timestamps.
- Context-ladder leg start and end timestamps for each prompt-token target, plus status and exit code.
- Server-reported eval tokens per second when available.
- GPU power, clock, memory clock, temperature, and memory usage before and after the run.

## Context Ladder

Use actual generated benchmark context to fill the prompt. Do not use blank filler, repeated punctuation, or synthetic nonsense that makes attention unrealistically easy.

The default long-context task is a continuity-heavy book/project-bible prompt. It asks the model to write from a large structured source document, which stresses long-context retrieval, instruction following, and generation speed in a way that resembles real agent work.

Recommended ladder:

- Canonical: `8192`, `32768`, `65536`, `131072`, `200000` prompt-token targets.
- Human-friendly: `10000`, `50000`, `100000`, `200000` prompt-token targets.

The benchmark records actual `prompt_tokens` from the endpoint response when the runtime reports usage. Use actual measured prompt tokens in summaries, not only the requested target.

The ladder must run against one already-loaded model server. Do not restart or reload the model between prompt-token targets. Start the server once at `262144` context, then send the ladder requests sequentially to the same endpoint. The summary CSV is checkpointed with `running`, then `ok` or `failed`, for each target before moving on.

## First Sweep

For `Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf`, start with the current launcher:

```text
D:\Tools\LocalAI\start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Then benchmark the endpoint:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmarks\bench-context-ladder.ps1 `
  -BaseUrl http://127.0.0.1:39182/v1 `
  -Model qwopus3.6-27b-coder-mtp-q5-k-m `
  -CasePrefix qwopus-coder-mtp-q5-ctx256k-mtp `
  -GpuIndex 0 `
  -MaxTokens 1024 `
  -Runs 3
```

For `Qwen3.6-27B-Text-NVFP4-MTP`, start the vLLM launcher and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmarks\bench-context-ladder.ps1 `
  -BaseUrl http://127.0.0.1:8892/v1 `
  -Model qwen3.6-27b-text-nvfp4-mtp `
  -CasePrefix qwen-text-nvfp4-ctx256k-mtp `
  -GpuIndex 0 `
  -MaxTokens 1024 `
  -Runs 3
```

Once a baseline is recorded, test one setting at a time:

- `--spec-draft-n-max`: `1`, `2`, `3`, `4`
- context: run the ladder through `200000` prompt-token targets when the launcher has a `256K` context window
- KV cache: current `q4_0/q4_0` against `q8_0/q8_0` and `f16/f16` if memory allows
- ngram plus MTP versus MTP-only

## Interpretation Rule

Prefer the fastest profile that is stable across longer runs. Do not choose a profile from a single short peak if it increases power, heat, shutdown risk, or result variance.
