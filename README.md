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

---

## RTX 5090 Benchmark Results

**GPU:** RTX 5090 32GB — **Driver:** 610.62 — **Dates:** 2026-06-22 to
2026-06-23

BookContext prompt ladder — gen=1024 tok — temperature=0 — 3 measured runs

![RTX 5090 long-context throughput comparison](assets/images/rtx-5090-context-ladder-comparison.svg)

### Qwopus3.6-27B-Coder-MTP-Q5_K_M

llama.cpp b9761 — ctx=256k — MTP n=2

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

Full per-run CSVs: `results/rtx-5090/`

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

**4. Wire into Hermes**

```
/provider add custom:qwopus-local http://127.0.0.1:39182/v1 <any-key>
/model custom:qwopus-local:qwopus3.6-27b-coder-mtp-q5-k-m
```

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

Run a single endpoint bench:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\benchmarks\bench-openai-chat-endpoint.ps1 `
  -BaseUrl http://127.0.0.1:39182/v1 `
  -Model qwopus3.6-27b-coder-mtp-q5-k-m `
  -TargetPromptTokens 8192 `
  -MaxTokens 1024
```

---

## Repo Structure

```
scripts/
  localai/
    qwopus3.6-27b-coder-mtp-gguf/   launchers, download, install
  vllm/
    aeon-qwen36-27b-multimodal-nvfp4-mtp-xs/  Docker vLLM launcher
  benchmarks/
    bench-context-ladder.ps1         full context ladder sweep
    bench-openai-chat-endpoint.ps1   single endpoint benchmark
    download-hf-artifact.py          HF download helper
docs/
  models/qwopus3.6-27b-coder-mtp-gguf.md   model notes
  models/aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.md   AEON vLLM notes
  hardware/rtx-5090-power-and-thermal.md    GPU tuning notes
  integrations/hermes-desktop.md            Hermes wiring guide
results/
  rtx-5090/                                 benchmark CSVs + README
```
