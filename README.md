# NVIDIA Local LLM Profiles

Launch profiles, LocalAI helpers, benchmark harnesses, and Hermes setup notes for running local LLMs on NVIDIA GPUs, with RTX 5090 as the first max-performance tuning target and RTX 3090 as the secondary target.

![RTX 5090 MSI Afterburner voltage/frequency curve](assets/images/rtx-5090-msi-afterburner-vf-curve.png)

The RTX 5090 should use the saved MSI Afterburner voltage/frequency curve before long inference or benchmark runs. The curve editor profile is part of the operating recipe because long stock-curve inference can waste power and trigger thermal shutdown behavior on this machine. See `docs/hardware/rtx-5090-power-and-thermal.md`.

The current targets are:

- `sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP`
- `Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF`
- Runtime mix: vLLM Docker for ModelOpt NVFP4 safetensors, llama.cpp CUDA for GGUF
- Local model folder: `D:\Tools\LocalAI\models`
- Hermes integration: OpenAI-compatible `/v1` endpoints

## For AI Agents

Treat these files as the operational source of truth:

- Hermes integration: `docs/integrations/hermes-desktop.md`
- RTX 5090 power and thermal notes: `docs/hardware/rtx-5090-power-and-thermal.md`
- RTX 5090 benchmark plan: `docs/benchmarks/rtx-5090-benchmark-plan.md`
- Qwen NVFP4 model notes: `docs/models/qwen3.6-27b-text-nvfp4-mtp.md`
- Qwopus Coder MTP model notes: `docs/models/qwopus3.6-27b-coder-mtp-gguf.md`
- Endpoint benchmark script: `scripts/benchmarks/bench-openai-chat-endpoint.ps1`
- Context ladder benchmark script: `scripts/benchmarks/bench-context-ladder.ps1`
- Qwen LocalAI pack: `scripts/localai/qwen3.6-27b-text-nvfp4-mtp/`
- Qwopus LocalAI pack: `scripts/localai/qwopus3.6-27b-coder-mtp-gguf/`
- Install all LocalAI launchers: `scripts/localai/install-all-localai-launchers.bat`

Important behavior:

- Do not assume this project is only for GGUF. NVIDIA local LLM profiling includes both GGUF/llama.cpp and NVFP4/vLLM paths.
- The Qwen NVFP4 model is not a GGUF; use the vLLM launcher.
- The Qwopus Coder MTP model is a GGUF; use the llama.cpp CUDA launcher.
- Keep model payloads out of this repo. Store downloaded models in `D:\Tools\LocalAI\models`.
- For RTX 5090 long runs, verify the Afterburner voltage/frequency curve is applied before starting benchmarks.
- Benchmark results must record model, runtime, launch settings, GPU index, power/thermal state, prompt style/hash, requested prompt-token target, actual prompt tokens, generated tokens, and throughput.
- Benchmark CSVs must include request start/end timestamps, and context ladder runs must write a summary CSV with start/end timestamps for each prompt-token target.
- Long-context tests must use actual generated benchmark context, not empty filler. The default long-context prompt is a continuity-heavy book/project bible task.
- Only use `draft-mtp` when the model actually includes an MTP head.
- Hermes Desktop can use `127.0.0.1`; Hermes Client on another machine needs the LAN or Tailscale URL and a matching firewall rule.

## Quick Start

Install both LocalAI launcher packs:

```text
scripts\localai\install-all-localai-launchers.bat
```

For Qwen3.6 Text NVFP4 MTP:

```text
scripts\localai\qwen3.6-27b-text-nvfp4-mtp\download-to-LocalAI-models.bat
D:\Tools\LocalAI\start-qwen3.6-27B-Text-NVFP4-MTP-server.bat
```

For Qwopus3.6 Coder MTP GGUF:

```text
D:\Tools\LocalAI\models\Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf
D:\Tools\LocalAI\start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

## Hermes Endpoints

Qwen NVFP4 vLLM:

- Desktop base URL: `http://127.0.0.1:8892/v1`
- Model: `qwen3.6-27b-text-nvfp4-mtp`

Qwopus Coder MTP GGUF:

- Desktop base URL: `http://127.0.0.1:39182/v1`
- LAN base URL: `http://192.168.68.73:39182/v1`
- Tailscale base URL: `http://100.64.131.86:39182/v1`
- Model: `qwopus3.6-27b-coder-mtp-q5-k-m`

See `docs/integrations/hermes-desktop.md` for the combined setup notes.

## RTX 5090 Benchmarking

The primary RTX 5090 sweep measures speed at increasing prompt/context pressure using actual generated benchmark text. Prefer this ladder:

- Canonical ladder: `8192`, `32768`, `65536`, `131072`, `200000` prompt-token targets.
- Human-friendly comparison ladder: `10000`, `50000`, `100000`, `200000` prompt-token targets.

The canonical ladder is preferred because powers of two line up better with runtime/cache behavior. The human-friendly ladder is useful when communicating results.

Benchmark protocol:

- Benchmark one model at a time. Stop the first model before loading the second.
- Start the model server once at `262144` context.
- Keep that same model loaded for the entire ladder; do not restart or reload between prompt targets.
- Send ladder requests sequentially to the same OpenAI-compatible endpoint.
- Use `BookContext`, a generated continuity-heavy book/project-bible prompt, to fill real context instead of repeated filler.
- Generate `1024` tokens per request unless a specific run says otherwise.
- Write each prompt target's detailed CSV immediately after that target completes.
- Checkpoint the ladder summary CSV before each target starts with `status=running`, then update it to `ok` or `failed` when that target ends.
- Continue to the next target even if one target fails, so partial results still survive.

After starting a local model server, run the context ladder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmarks\bench-context-ladder.ps1 `
  -BaseUrl http://127.0.0.1:39182/v1 `
  -Model qwopus3.6-27b-coder-mtp-q5-k-m `
  -CasePrefix qwopus-coder-mtp-q5-ctx256k-mtp `
  -GpuIndex 0 `
  -MaxTokens 1024 `
  -Runs 3
```

For Qwen NVFP4/vLLM, use the same ladder against the vLLM endpoint:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmarks\bench-context-ladder.ps1 `
  -BaseUrl http://127.0.0.1:8892/v1 `
  -Model qwen3.6-27b-text-nvfp4-mtp `
  -CasePrefix qwen-text-nvfp4-ctx256k-mtp `
  -GpuIndex 0 `
  -MaxTokens 1024 `
  -Runs 3
```

For the round-number ladder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmarks\bench-context-ladder.ps1 `
  -BaseUrl http://127.0.0.1:39182/v1 `
  -Model qwopus3.6-27b-coder-mtp-q5-k-m `
  -CasePrefix qwopus-coder-mtp-q5-round-context `
  -GpuIndex 0 `
  -PromptTokenTargets 10000,50000,100000,200000 `
  -MaxTokens 1024 `
  -Runs 3
```

For a single point, run the endpoint benchmark directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\benchmarks\bench-openai-chat-endpoint.ps1 `
  -BaseUrl http://127.0.0.1:39182/v1 `
  -Model qwopus3.6-27b-coder-mtp-q5-k-m `
  -CaseName qwopus-coder-mtp-q5-ctx32k-draft2 `
  -GpuIndex 0 `
  -PromptStyle BookContext `
  -TargetPromptTokens 32768 `
  -MaxTokens 512 `
  -Runs 3
```

Write RTX 5090 results under `results/rtx-5090/`.

## Repo Layout

- `scripts/localai/qwen3.6-27b-text-nvfp4-mtp/`: Qwen NVFP4 download, vLLM server, and shortcut helpers.
- `scripts/localai/qwopus3.6-27b-coder-mtp-gguf/`: Qwopus Coder GGUF llama.cpp server and firewall helper.
- `scripts/localai/install-all-localai-launchers.*`: install both packs into `D:\Tools\LocalAI`.
- `scripts/benchmarks/bench-openai-chat-endpoint.ps1`: benchmark any running OpenAI-compatible local endpoint.
- `scripts/benchmarks/bench-context-ladder.ps1`: run the standard long-context prompt ladder.
- `docs/hardware/`: GPU-specific operating notes.
- `docs/benchmarks/`: benchmark plans and result schemas.
- `docs/models/`: model-specific operational notes.
- `docs/integrations/`: Hermes Desktop and Hermes Client setup.
- `results/`: benchmark outputs when tuning profiles.
- `patches/`: local patch records if a runtime needs patching.
