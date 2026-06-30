# nvidia-local-llm-profiles

RTX 5090 local LLM optimization profiles — benchmarks, launchers, and Hermes
integration for running high-performance local inference on NVIDIA Blackwell.

Hand this repo to a coding agent and it can download the model, start a local
OpenAI-compatible endpoint, wire Hermes, run benchmarks, and collect the proof.

**Current focus:** Qwopus3.6-35B-A3B-Coder-MTP Q4_K_M and Q5_K_M via native
llama.cpp, with Qwopus27, Ornith, AEON Ornith, and Unsloth Qwen35 kept as RTX
5090 comparison baselines.

---

## Model

**Qwopus3.6-27B-Coder-MTP-Q5_K_M** — a merged/tuned Qwen3.6 27B coder model with
embedded MTP draft head, quantized to Q5_K_M GGUF. Runs via llama.cpp with
`--spec-type draft-mtp` for speculative decoding.

Hugging Face model: [Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF](https://huggingface.co/Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF)

Credit and lineage:

- Primary GGUF release: [Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF](https://huggingface.co/Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF)
- Base model card: [Jackrong/Qwopus3.6-27B-v2](https://huggingface.co/Jackrong/Qwopus3.6-27B-v2)
- The model card credits the Qwen team for the Qwen3.6-27B base, Jackrong for
  the Qwopus training work, and the MTP/GGUF release for local speculative
  decoding.

Why this profile uses it:

- It is a current best-fit coding model for RTX 5090-class local inference:
  large enough for strong repository-level coding and tool-use behavior, while
  still fitting on a 32GB Blackwell card as a Q5_K_M GGUF.
- The MTP draft head lets llama.cpp use speculative decoding for much higher
  interactive throughput.
- With the 256k llama.cpp profile here, it keeps full long-context operation on
  the 5090 without dropping to a smaller coding model.
- A Q4_K_M launcher is included as a lower-VRAM fallback when Q5_K_M cannot fit
  the desired context on a single 32GB card.

> Note: A Hugging Face account may be required to download. Run
> `huggingface-cli login` and set up a token at huggingface.co/settings/tokens
> if you get a 401 error.

---

## Additional Model Support

### AEON Qwen3.6 27B Multimodal NVFP4 MTP-XS

This repo also includes a vLLM/Docker support folder for
[AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP-XS](https://huggingface.co/AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP-XS).

Use this when you want to test the AEON XS safetensors/modelopt NVFP4 path on
RTX 5090-class hardware. It is not a GGUF/llama.cpp profile; the tested Windows
launcher serves it with `vllm/vllm-openai:latest`, fp8 KV cache, and a 200k
context cap.

Observed Windows note: AEON NVFP4 loaded and completed the benchmark ladder, but
throughput was lower than hoped on this setup. Treat these numbers as a Windows
driver/container/NVFP4 compatibility baseline, not as the model's likely ceiling.

Launcher folder:

```text
scripts\vllm\aeon-qwen36-27b-multimodal-nvfp4-mtp-xs\
```

Quick path:

```bat
download-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.bat
start-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-docker.bat
bench-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-context-ladder.bat
```

Endpoint defaults:

- Base URL: `http://127.0.0.1:39183/v1`
- Model: `aeon-qwen36-27b-multimodal-nvfp4-mtp-xs`
- Benchmark case prefix: `aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-fp8kv-ctx200k`

See `docs/models/aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.md` for the model
notes and serving assumptions.

### NVIDIA Qwen3.6 35B A3B NVFP4 MoE

Minimal vLLM/Docker support for
[nvidia/Qwen3.6-35B-A3B-NVFP4](https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4).
This profile only runs the quick two-point check requested here: about 10k and
200k prompt tokens, one measured run each. The benchmark helper uses the saved
prompt fixtures in `benchmarks/prompts/` so the NVFP4 rows are tested against
the same text as the GGUF endpoint rows.

Launcher folder:

```text
scripts\vllm\qwen36-35b-a3b-nvfp4\
```

### Qwopus3.6 35B A3B Coder MTP GGUF

Native llama.cpp support for
[Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF](https://huggingface.co/Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF),
using `Qwopus3.6-35B-A3B-Coder-MTP-Q4_K_M.gguf` or
`Qwopus3.6-35B-A3B-Coder-MTP-Q5_K_M.gguf`.

Launcher folder:

```text
scripts\localai\qwopus3.6-35b-a3b-coder-mtp-gguf\
```

Quick path:

```bat
download-qwopus3.6-35b-a3b-coder-mtp-q4-k-m.bat
start-qwopus3.6-35b-a3b-coder-mtp-q4-k-m-server.bat
bench-qwopus3.6-35b-a3b-coder-mtp-q4-k-m-two-point.bat

download-qwopus3.6-35b-a3b-coder-mtp-q5-k-m.bat
start-qwopus3.6-35b-a3b-coder-mtp-q5-k-m-server.bat
bench-qwopus3.6-35b-a3b-coder-mtp-q5-k-m-two-point.bat
```

Endpoint defaults:

- Q4 Base URL: `http://127.0.0.1:39193/v1`
- Q4 Model: `qwopus3.6-35b-a3b-coder-mtp-q4-k-m`
- Q5 Base URL: `http://127.0.0.1:39191/v1`
- Q5 Model: `qwopus3.6-35b-a3b-coder-mtp-q5-k-m`
- Context cap: `200000`
- Serving path: native Windows llama.cpp only; no Docker profile is needed.

### Unsloth Qwen3.6 35B A3B MTP GGUF

Minimal llama.cpp support for
[unsloth/Qwen3.6-35B-A3B-MTP-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-MTP-GGUF),
using `Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf`.

Launcher folder:

```text
scripts\localai\qwen36-35b-a3b-mtp-gguf\
```

### DeepReinforce Ornith 1.0 35B GGUF

Minimal llama.cpp support for
[deepreinforce-ai/Ornith-1.0-35B-GGUF](https://huggingface.co/deepreinforce-ai/Ornith-1.0-35B-GGUF),
using `ornith-1.0-35b-Q4_K_M.gguf` and `ornith-1.0-35b-Q5_K_M.gguf`.

Launcher folder:

```text
scripts\localai\ornith-1.0-35b-gguf\
```

Q5_K_M quick path:

```bat
download-ornith-1.0-35b-q5-k-m.bat
start-ornith-1.0-35b-q5-k-m-server.bat
bench-ornith-1.0-35b-q5-k-m-two-point.bat
```

Ornith is a reasoning model, so the foreground launcher leaves reasoning mode
on by default. Use `-NoThinking` in the benchmark wrapper or set `THINKING=0`
in the `.bat` file for no-think latency experiments.

### AEON Ornith 1.0 35B Ultimate Uncensored NVFP4

Docker/vLLM support for
[AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4](https://huggingface.co/AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4),
a compressed-tensors NVFP4 safetensors profile for Blackwell GPUs.

Launcher folder:

```text
scripts\vllm\aeon-ornith-1.0-35b-nvfp4\
```

Quick path:

```bat
download-aeon-ornith-1.0-35b-nvfp4.bat
start-aeon-ornith-1.0-35b-nvfp4-vllm-docker.bat
bench-aeon-ornith-1.0-35b-nvfp4-two-point.bat
```

Endpoint defaults:

- Base URL: `http://127.0.0.1:39187/v1`
- Model: `aeon-ornith-1.0-35b-nvfp4`

---

## RTX 5090 Benchmark Results

**GPU:** RTX 5090 32GB - **Driver:** 610.62 - **Dates:** 2026-06-22 to
2026-06-30

Headline chart: native Windows llama.cpp GGUF endpoints only, using the checked-in
BookContext 10k and 200k prompts with 1024 generated tokens. Bars are llama.cpp
generation/decode tok/s after prompt prefill; prompt prefill seconds are labeled
separately. Docker/vLLM and manual UI observations are kept in
`results/rtx-5090/README.md`.

![RTX 5090 native llama.cpp long-context comparison](assets/images/rtx-5090-qwen35-moe-vs-qwopus.png)

Latest addition:

- `Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF` Q4_K_M and Q5_K_M loaded
  natively at `ctx=200000` (`n_ctx=200192`) with q4 target/draft KV,
  `ngram-mod,draft-mtp`, and request-level no-thinking.
- No-thinking proof: on the same server, an auto request produced
  `reasoning_content`, while a request with
  `chat_template_kwargs.enable_thinking=false` produced normal content without a
  reasoning block. The `Local 5090` router now injects that request default for
  Qwopus35.
- 10k reference prompt: **149.0 decode tok/s**, 112.8 full-wall tok/s after
  2.1s prefill.
- 200k reference prompt: **100.0 decode tok/s**, 15.4 full-wall tok/s after
  55.8s prefill.
- Q4_K_M no-thinking result: **181.0 decode tok/s** at 10k and **91.2 decode
  tok/s** at 200k. A Q4 n=3 MTP trial was slower than n=2 on the 10k check, so
  the chart uses `--spec-draft-n-max 2`.
- Prompt prefill is the model reading the input prompt into KV cache. No-thinking
  prevents generated reasoning blocks, but it does not skip reading a 200k
  prompt; the fresh 200k run still processed 166,199 new prompt tokens after
  reusing the 10k prefix from the previous request.
- Peak observed memory after request: 27.6 GiB at 10k and 28.4 GiB at 200k
  from the recorded `nvidia-smi` MiB fields.

The 10k and 200k reference prompts are checked in at
`benchmarks/prompts/book-context-10k.txt` and
`benchmarks/prompts/book-context-200k.txt`. Their SHA256 values are
`785c5b31d1ce77612431b1289c0a097ed51ab1a6d4a07bccfb7a70f59df55f94` and
`a794ca243983eb3387bec6728db4b0c72a99ee2a98cfee7223269708e4ae228c`.

Detailed CSVs, Docker/vLLM experiments, manual UI observations, the older
Qwopus27 ladder, and the AEON Ornith Docker-vs-GGUF chart live in
`results/rtx-5090/README.md`.

---

## Windows Stability Note

Apply a conservative MSI Afterburner voltage/frequency curve before long
Windows inference runs on the RTX 5090. On this Windows test box, leaving stock
boost behavior in place can crash during sustained high-VRAM LLM runs.

![RTX 5090 MSI Afterburner voltage/frequency curve](assets/images/rtx-5090-msi-afterburner-vf-curve.png)

Why this matters:

- Sustained local LLM inference is a VRAM-heavy load, not a short gaming burst.
- Some cards cannot hold aggressive core clocks while VRAM stays heavily
  occupied for long-context runs.
- The goal is stable model and KV-cache residency in 32GB VRAM; max core clock is
  less important than avoiding crashes and throttling.
- A lower, flatter curve also saves electricity because it avoids spending power
  on core boost that does not materially improve this profile.

See `docs/hardware/rtx-5090-power-and-thermal.md` for the full checklist.

---

## Quick Start

**1. Download the model**

```bat
scripts\localai\qwopus3.6-27b-coder-mtp-gguf\download-qwopus3.6-27B-Coder-MTP-Q5.bat
```

**2. Install the launcher**

```powershell
powershell -ExecutionPolicy Bypass -File scripts\localai\qwopus3.6-27b-coder-mtp-gguf\install-to-LocalAI.ps1
```

**3. Start the server**

```bat
start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Serves OpenAI-compatible endpoint at `http://127.0.0.1:39182/v1`

**4. Use Hermes Desktop**

Install the Hermes `Local 5090` provider and local router:

```bat
scripts\hermes\install-local-5090-provider.bat
```

Start the model server you want from `scripts\localai\`. For example, Ornith Q5:

```bat
scripts\localai\ornith-1.0-35b-gguf\start-ornith-1.0-35b-q5-k-m-server.bat
```

Or Qwopus:

```bat
scripts\localai\qwopus3.6-27b-coder-mtp-gguf\start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Or Qwopus 35B:

```bat
scripts\localai\qwopus3.6-35b-a3b-coder-mtp-gguf\start-qwopus3.6-35b-a3b-coder-mtp-q4-k-m-server.bat
scripts\localai\qwopus3.6-35b-a3b-coder-mtp-gguf\start-qwopus3.6-35b-a3b-coder-mtp-q5-k-m-server.bat
```

Then restart or open Hermes Desktop, choose the `Local 5090` provider, and pick
the model you started. You can also point any OpenAI-compatible client at the
router:

```text
Base URL: http://127.0.0.1:39190/v1
Model:    qwopus3.6-35b-a3b-coder-mtp-q4-k-m
```

The installer updates Hermes Desktop with a single `Local 5090` provider:

- `qwopus3.6-27b-coder-mtp-q5-k-m` routes to `http://127.0.0.1:39182/v1`
- `qwopus3.6-35b-a3b-coder-mtp-q5-k-m` routes to `http://127.0.0.1:39191/v1`
- `qwopus3.6-35b-a3b-coder-mtp-q4-k-m` routes to `http://127.0.0.1:39193/v1`
- `diffusiongemma` routes to `http://127.0.0.1:8890/v1`
- `aeon-ornith-1.0-35b-nvfp4` routes to `http://127.0.0.1:39187/v1`
- `ornith-1.0-35b-q4-k-m` routes to `http://127.0.0.1:39188/v1`
- `ornith-1.0-35b-q5-k-m` routes to `http://127.0.0.1:39189/v1`
- Hermes talks to the local router at `http://127.0.0.1:39190/v1`
- The script backs up `%LOCALAPPDATA%\hermes\config.yaml` before editing it.

Hermes uses one base URL per provider, so the tiny router lets these local model
servers appear together under `Local 5090`.

![Hermes Desktop Local 5090 provider](assets/images/hermes-local-5090-provider.png)

See `docs/integrations/hermes-desktop.md` for the exact config shape and router
details.

---

## Benchmarking

Run a context ladder:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\benchmarks\bench-context-ladder.ps1
```

Render the benchmark chart:

```powershell
python scripts\benchmarks\render-rtx5090-context-chart.py
python scripts\benchmarks\render-qwen35-moe-comparison-chart.py
```

Requires Matplotlib (`pip install matplotlib`) if your Python environment does
not already include it.

Run a single endpoint bench:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\benchmarks\bench-openai-chat-endpoint.ps1 `
  -BaseUrl http://127.0.0.1:39182/v1 `
  -Model qwopus3.6-27b-coder-mtp-q5-k-m `
  -PromptFile benchmarks\prompts\book-context-10k.txt `
  -PromptStyle BookContext `
  -TargetPromptTokens 10000 `
  -MaxTokens 1024
```

For manual UI comparisons, paste the saved benchmark prompt as plain text
instead of dragging it in as a file. File attachment modes can route through RAG
or document retrieval, which changes the actual prompt tokens seen by the model.

---

## Repo Structure

```
scripts/
  hermes/
    install-local-5090-provider.bat    add the Local 5090 Hermes provider
    local-5090-router.py               local model router used by Hermes
  localai/
    qwopus3.6-27b-coder-mtp-gguf/   launchers, download, install
    qwopus3.6-35b-a3b-coder-mtp-gguf/  Qwopus 35B Coder GGUF launcher
    qwen36-35b-a3b-mtp-gguf/        Unsloth Qwen 35B GGUF launcher
    ornith-1.0-35b-gguf/            Ornith 35B GGUF launcher
  vllm/
    aeon-ornith-1.0-35b-nvfp4/       AEON Ornith NVFP4 Docker vLLM launcher
    aeon-qwen36-27b-multimodal-nvfp4-mtp-xs/  Docker vLLM launcher
    qwen36-35b-a3b-nvfp4/            NVIDIA MoE NVFP4 two-point bench
  benchmarks/
    bench-context-ladder.ps1         full context ladder sweep
    bench-openai-chat-endpoint.ps1   single endpoint benchmark
    download-hf-artifact.py          HF download helper
    render-aeon-ornith-windows-comparison-chart.py  AEON Ornith chart
    render-qwen35-moe-comparison-chart.py     native llama.cpp 35B comparison chart
docs/
  models/qwopus3.6-27b-coder-mtp-gguf.md   model notes
  models/aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.md   AEON vLLM notes
  hardware/rtx-5090-power-and-thermal.md    GPU tuning notes
  integrations/hermes-desktop.md            Hermes wiring guide
results/
  rtx-5090/                                 benchmark CSVs + README
```
