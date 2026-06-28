# nvidia-local-llm-profiles

RTX 5090 local LLM optimization profiles — benchmarks, launchers, and Hermes
integration for running high-performance local inference on NVIDIA Blackwell.

Hand this repo to a coding agent and it can download the model, start a local
OpenAI-compatible endpoint, wire Hermes, run benchmarks, and collect the proof.

**Current focus:** Qwopus3.6-27B-Coder-MTP Q5_K_M via llama.cpp, plus AEON
Qwen3.6 27B Multimodal NVFP4 MTP-XS via vLLM.

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

**GPU:** RTX 5090 32GB — **Driver:** 610.62 — **Dates:** 2026-06-22 to
2026-06-27

BookContext prompt ladder — gen=1024 tok — temperature=0 — 3 measured runs

![RTX 5090 long-context throughput comparison](assets/images/rtx-5090-context-ladder-comparison.png)

### Qwopus3.6-27B-Coder-MTP-Q5_K_M

llama.cpp b9761 — ctx=256k — MTP n=2

![RTX 5090 Qwopus long-context throughput](assets/images/rtx-5090-qwopus-context-ladder.png)

| Context | avg tok/s | Power | Temp |
| ---: | ---: | ---: | ---: |
| 8k | **109 tok/s** | 355W | 54C |
| 33k | 82 tok/s | 351W | 58C |
| 66k | 91 tok/s | 354W | 63C |
| 131k | 63 tok/s | 341W | 65C |
| 200k | 51 tok/s | 340W | 67C |
| 256k | 65 tok/s | 340W | 64C |

### AEON Qwen3.6 27B Multimodal NVFP4 MTP-XS

vLLM OpenAI — modelopt NVFP4 — fp8 KV — ctx=200k — qwen3_5_mtp

| Context | avg tok/s | Power | Temp |
| ---: | ---: | ---: | ---: |
| 8k | 48 tok/s | 162W | 47C |
| 33k | 45 tok/s | 170W | 50C |
| 66k | 41 tok/s | 176W | 53C |
| 131k | 39 tok/s | 187W | 57C |
| 200k | 36 tok/s | 216W | 59C |

AEON completed the 8k-200k ladder, but this Windows setup did not produce high
NVFP4 throughput. A possible culprit is the modelopt NVFP4 path on this specific
Windows/container/driver stack rather than a simple VRAM limit.

Full per-run CSVs: `results/rtx-5090/`

### AEON Ornith 1.0 35B NVFP4 — Docker vLLM vs native GGUF

![AEON Ornith NVFP4 on Windows, Docker vLLM vs native GGUF llama.cpp](assets/images/aeon-ornith-windows-docker-vs-gguf.png)

Native Windows GGUF loaded successfully through llama.cpp with
`BLACKWELL_NATIVE_FP4 = 1`. The chart uses native GGUF decode speed where
llama.cpp exposed the split. Docker/vLLM bars are labeled as full-request wall
proxies because that run did not capture a separate decode-only number.
Official GGUF mirror and model card:
[neko-legends/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4-GGUF](https://huggingface.co/neko-legends/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4-GGUF).

- Native GGUF 10k: **133.0 decode tok/s**, 106.0 full-wall tok/s after 1.9s prefill.
- Native NVFP4+MTP 10k: **137.9 decode tok/s** at temp=0.6, 106.8 full-wall tok/s after 2.0s prefill.
- Native GGUF 200k: **82.1 decode tok/s**, 18.9 full-wall tok/s after 41.0s prefill.
- Native NVFP4+MTP 200k: **90.4 decode tok/s** at temp=0.6, 16.4 full-wall tok/s after 50.3s prefill.
- Docker/vLLM finished the 200k full request faster in this run, but only
  full-wall timing was captured for Docker.
- MTP note: the working MTP artifact is
  [s-batman/Ornith-1.0-35B-NVFP4-MTP-GGUF](https://huggingface.co/s-batman/Ornith-1.0-35B-NVFP4-MTP-GGUF),
  which grafts a Qwen3.6 MTP block into an Ornith NVFP4 GGUF. AEON's
  compressed-tensors safetensors release advertises MTP in config metadata, but
  the downloaded tensors did not contain the `blk.40.*` MTP weights.
- Greedy tuning note: with `draft-mtp,ngram-mod`, `n_max=3`, q4 target/draft
  KV, and temp=0, the warm 10k pass reached **152.7 decode tok/s** and
  **150.2 full-wall tok/s**.

### Qwen3.6 35B Local Variants

Two-point comparison rows. The chart bars and table use generation speed where
that timing split was captured; prompt read / prefill time is listed separately.

![RTX 5090 local coding-model throughput with automated and manual Studio rows](assets/images/rtx-5090-qwen35-moe-vs-qwopus.png)

| Model / source | Context | Actual / reported context tokens | generation tok/s | Prompt read / prefill | Timing source |
| --- | ---: | ---: | ---: | ---: | --- |
| Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF Q5_K_M, llama.cpp endpoint | 10k reference | 8,907 | 79.5 tok/s | 3.9s | llama.cpp log |
| Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF Q5_K_M, llama.cpp endpoint | 200k target | 174,588 | 70.2 tok/s | ~75.6s | repeat-run estimate |
| Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF Q5_K_M, pasted text (Unsloth Studio) | 9.5k inferred | 9,496 | 65.7 tok/s | 3.8s | UI screenshot |
| Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF Q5_K_M, file run (Unsloth Studio) | 176k reported | 176,000 | 21.4 tok/s | 210.9s | UI screenshot |
| Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF Q4_K_M, llama.cpp endpoint | 10k reference | 8,908 | 89.2 tok/s | 3.8s | llama.cpp log |
| Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF Q4_K_M, llama.cpp endpoint | 200k target | 174,591 | 46.4 tok/s | 141.1s | llama.cpp log |
| unsloth/Qwen3.6-35B-A3B-MTP-GGUF UD-Q4_K_XL, llama.cpp endpoint | 10k target | 8,907 | 126.9 tok/s | 2.4s | llama.cpp log |
| unsloth/Qwen3.6-35B-A3B-MTP-GGUF UD-Q4_K_XL, file run (Unsloth Studio) | 13k reported | 13,000 | 121.1 tok/s | n/a | UI screenshot |
| unsloth/Qwen3.6-35B-A3B-MTP-GGUF UD-Q4_K_XL, llama.cpp endpoint | 200k target | 174,590 | 89.5 tok/s | 57.1s | llama.cpp log |
| unsloth/Qwen3.6-35B-A3B-MTP-GGUF UD-Q4_K_XL, file run (Unsloth Studio, 5090 only) | 179.5k reported | 179,500 | 95.7 tok/s | 49.4s | UI screenshot |
| nvidia/Qwen3.6-35B-A3B-NVFP4 | 10k reference | 8,905 | 92.0 tok/s | n/a | full-request timing, split unavailable |
| nvidia/Qwen3.6-35B-A3B-NVFP4 | 200k reference | 174,588 | 30.5 tok/s | n/a | full-request timing, split unavailable |
| deepreinforce-ai/Ornith-1.0-35B-GGUF Q4_K_M, llama.cpp endpoint | 10k reference | 8,905 | 201.5 tok/s | 1.7s | llama.cpp log |
| deepreinforce-ai/Ornith-1.0-35B-GGUF Q4_K_M, file run (Unsloth Studio) | 9.5k inferred | 9,498 | 127.2 tok/s | 1.8s | UI screenshot |
| deepreinforce-ai/Ornith-1.0-35B-GGUF Q4_K_M, llama.cpp endpoint | 200k target | 174,588 | 106.7 tok/s | 40.3s | llama.cpp log |
| deepreinforce-ai/Ornith-1.0-35B-GGUF Q4_K_M, file run (Unsloth Studio) | 175.2k inferred | 175,188 | 89.9 tok/s | 39.7s | UI screenshot |

Ornith Unsloth Studio long-context proof:

![Ornith 1.0 35B GGUF in Unsloth Studio at 89.9 tok/s near 175k context](assets/images/ornith-unsloth-studio-175k-proof.png)

The NVIDIA NVFP4 vLLM profile loaded with a 200k max context and used roughly
30GB VRAM while idle, but the captured vLLM run did not include a prompt-vs-
generation timing split.

Token accounting note: these benchmark prompts are sent inline as the user
message in an OpenAI-compatible chat completion request. The chart separates
generation speed from prompt read / prefill time when the runtime exposed that
split. UI tests that drag in a file may use attachment or RAG behavior instead
of putting the whole file into the model context, and UI tok/s counters may
report decode-only speed.

The 10k and 200k reference prompts are checked in at
`benchmarks/prompts/book-context-10k.txt` and
`benchmarks/prompts/book-context-200k.txt` so Q4/Q5, Unsloth 35B, NVIDIA NVFP4,
and future runtimes can be compared against the same text. Their SHA256 values
are `785c5b31d1ce77612431b1289c0a097ed51ab1a6d4a07bccfb7a70f59df55f94` and
`a794ca243983eb3387bec6728db4b0c72a99ee2a98cfee7223269708e4ae228c`.

Rows marked `(Unsloth Studio)` are manual observations from pasted-text or
file-added runs on the same Windows RTX 5090 box. They are useful real-world UI data points,
but not strict replacements for the endpoint benchmark rows. In the chart these
manual Studio rows use the coral source color. The short Qwopus
Studio row is a cleaner pasted-text run after restarting Studio/command prompt,
with the RTX 3090 no longer used. The 176k Qwopus Studio row is especially
tentative because Studio appeared to keep using the RTX 3090 even after tensor
parallelism was disabled. The 179.5k Unsloth Studio row was run after launching
Studio with only the RTX 5090 visible via `CUDA_VISIBLE_DEVICES=0`.

A follow-up run with display output moved from the RTX 5090 to the RTX 3090 did
not materially change Unsloth GGUF throughput: 95.8 tok/s at 10k and 14.7 tok/s
at 200k. The headless 5090 run is kept in the CSVs, but not charted.

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

Then restart or open Hermes Desktop, choose the `Local 5090` provider, and pick
the model you started. You can also point any OpenAI-compatible client at the
router:

```text
Base URL: http://127.0.0.1:39190/v1
Model:    ornith-1.0-35b-q5-k-m
```

The installer updates Hermes Desktop with a single `Local 5090` provider:

- `qwopus3.6-27b-coder-mtp-q5-k-m` routes to `http://127.0.0.1:39182/v1`
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
    render-qwen35-moe-comparison-chart.py     MoE vs Qwopus chart
docs/
  models/qwopus3.6-27b-coder-mtp-gguf.md   model notes
  models/aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.md   AEON vLLM notes
  hardware/rtx-5090-power-and-thermal.md    GPU tuning notes
  integrations/hermes-desktop.md            Hermes wiring guide
results/
  rtx-5090/                                 benchmark CSVs + README
```
