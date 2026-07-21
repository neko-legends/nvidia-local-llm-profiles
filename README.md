# nvidia-local-llm-profiles

RTX 5090 local LLM optimization profiles — benchmarks, launchers, and Hermes
integration for running high-performance local inference on NVIDIA Blackwell.

Hand this repo to a coding agent and it can download the model, start a local
OpenAI-compatible endpoint, wire Hermes, run benchmarks, and collect the proof.

**Current focus:** Qwopus3.6-35B-A3B-Coder-MTP Q4_K_M and Q5_K_M via native
llama.cpp, with Qwopus27, NVIDIA Qwen NVFP4, Ornith, AEON Ornith, and Unsloth
Qwen35 kept as RTX 5090 comparison baselines.

## Instructions for AI Agents

Treat each folder under `scripts\localai\` as a self-contained model profile.
The profile README and scripts are authoritative for that model; do not infer
paths or reuse flags from a different architecture.

| Requested model path | Profile folder |
| --- | --- |
| Qwopus 27B Coder MTP | `scripts\localai\qwopus3.6-27b-coder-mtp-gguf\` |
| Qwopus 35B A3B Coder MTP | `scripts\localai\qwopus3.6-35b-a3b-coder-mtp-gguf\` |
| NVIDIA Qwen3.6 27B NVFP4 MTP | `scripts\localai\qwen36-27b-nvfp4-gguf\` |
| NVIDIA Qwen3.6 35B A3B NVFP4 MTP | `scripts\localai\qwen36-35b-a3b-nvfp4-mtp-gguf\` |
| Unsloth Qwen3.6 35B A3B NVFP4 / Fast MTP | `scripts\localai\qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf\` |
| Qwen3.6 27B Q4_K_M + DFlash Q8_0 | `scripts\localai\qwen36-27b-dflash-gguf\` |
| ThinkingCap Qwen3.6 27B | `scripts\localai\thinkingcap-qwen36-27b-gguf\` |
| Ternary-Bonsai 27B + DSpark | `scripts\localai\ternary-bonsai-27b-gguf\` |
| Ornith 1.0 35B | `scripts\localai\ornith-1.0-35b-gguf\` |

Agent workflow:

1. Read the selected profile's `README.md` before running anything.
2. Install the shared Hermes provider once with `scripts\hermes\install-local-5090-provider.bat`.
3. Run the profile's download or conversion and runtime-build scripts in its documented order.
4. Run its Hermes installer, start its server, and select the matching model alias.
5. Keep model files in the checkout-parent `.local-model-cache`; never add GGUFs or safetensors to Git.
6. Confirm the advertised OpenAI-compatible endpoint and model alias before changing Hermes.
7. Verify complete CUDA0 layer offload and stop on CPU fallback, CUDA1 placement, allocation failure, or an unexpected context cap.
8. Use the checked-in benchmark fixtures and report prompt prefill separately from decode throughput.
9. For MTP, DFlash, or DSpark, report acceptance and mean accepted length; compare throughput only when prompts and generation settings match.

The regular user walkthrough remains in [Quick Start](#quick-start). This
section is intentionally a guardrail and routing index, not a duplicate setup
guide.

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

### NVIDIA Qwen3.6 27B NVFP4 MTP GGUF

Native llama.cpp scaffolding for a GGUF conversion of
[nvidia/Qwen3.6-27B-NVFP4](https://huggingface.co/nvidia/Qwen3.6-27B-NVFP4).
NVIDIA publishes the source checkpoint as a ModelOpt/NVFP4 safetensors release
with vLLM as the supported runtime. The source snapshot includes an MTP block,
and this folder keeps it in the native Windows GGUF path.

Launcher folder:

```text
scripts\localai\qwen36-27b-nvfp4-gguf\
```

Quick path:

```bat
download-qwen36-27b-nvfp4.bat

set LLAMA_CPP_SRC=C:\path\to\llama.cpp
convert-qwen36-27b-nvfp4-to-gguf.bat

set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
start-qwen36-27b-nvfp4-gguf-server.bat
```

Storage:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4\
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4-MTP-GGUF\qwen3.6-27b-nvfp4-mtp-gguf.gguf
```

Hermes:

```bat
scripts\localai\qwen36-27b-nvfp4-gguf\install-hermes-qwen36-27b-nvfp4-gguf.bat
```

Endpoint defaults:

- Base URL: `http://127.0.0.1:39195/v1`
- Model: `qwen36-27b-nvfp4-mtp-gguf`
- Context: `200000` on RTX 5090
- MTP: enabled by default with `draft-mtp`, `--spec-draft-n-max 2`
- Thinking: disabled by the launcher and Local 5090 router

Official safetensors Docker/vLLM baseline:

```bat
scripts\vllm\qwen36-27b-nvfp4\start-qwen36-27b-nvfp4-vllm-docker.bat
scripts\vllm\qwen36-27b-nvfp4\bench-qwen36-27b-nvfp4-vllm-two-point.bat
```

NVIDIA's official/recommended ModelOpt NVFP4 serving path is vLLM, using the
original safetensors checkpoint rather than GGUF. This repo's vLLM numbers are
from a **Windows 11 host with Docker Desktop**, which worked as a compatibility
path but did not behave like a high-performance native Linux vLLM setup. On the
RTX 5090 it loaded at 200k context without MTP and reported `223,880` GPU
KV-cache tokens, but it is tight: about `30.6 GiB` after requests. See
`scripts\vllm\qwen36-27b-nvfp4\qwen36-27b-nvfp4-vllm-notes.md`.

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

### NVIDIA Qwen3.6 35B A3B NVFP4 MTP GGUF

Native llama.cpp support for a GGUF conversion of
[nvidia/Qwen3.6-35B-A3B-NVFP4](https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4).
The converted GGUF keeps NVIDIA's native NVFP4 body and the bundled MTP block,
so recent llama.cpp builds can serve it with `--spec-type draft-mtp` on
Blackwell GPUs.

Launcher folder:

```text
scripts\localai\qwen36-35b-a3b-nvfp4-mtp-gguf\
```

Quick path:

```bat
set LLAMA_CPP_SRC=C:\path\to\llama.cpp
convert-qwen36-35b-a3b-nvfp4-mtp-to-gguf.bat

set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
start-qwen36-35b-a3b-nvfp4-mtp-gguf-server.bat
bench-qwen36-35b-a3b-nvfp4-mtp-gguf-two-point.bat
```

Output GGUF:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-35B-A3B-NVFP4-MTP-GGUF\qwen3.6-35b-a3b-nvfp4-mtp.gguf
```

Docker/vLLM support for the source NVFP4 snapshot is still available here:

```text
scripts\vllm\qwen36-35b-a3b-nvfp4\
```

### Unsloth Qwen3.6 NVFP4 MTP GGUFs

Native Windows llama.cpp profiles for Unsloth's mixed NVFP4/FP8 checkpoints:
[unsloth/Qwen3.6-27B-NVFP4](https://huggingface.co/unsloth/Qwen3.6-27B-NVFP4)
and [unsloth/Qwen3.6-35B-A3B-NVFP4](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-NVFP4).
The conversion keeps the bundled MTP block and writes the source FP8 weights as
Q8_0 while retaining native NVFP4 FFN tensors. That leaves usable KV-cache
headroom on an RTX 5090.

These source snapshots use a mixed compressed-tensors layout. Run this once if
your llama.cpp converter reports `Can't handle multiple config groups`:

```bat
set LLAMA_CPP_SRC=C:\path\to\llama.cpp
scripts\localai\apply-llama-cpp-mixed-nvfp4-converter-patch.bat
```

27B quick path:

```bat
cd scripts\localai\qwen36-27b-unsloth-nvfp4-mtp-gguf
download-qwen36-27b-unsloth-nvfp4.bat
convert-qwen36-27b-unsloth-nvfp4-to-gguf.bat
install-hermes-qwen36-27b-unsloth-nvfp4-mtp-gguf.bat

set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
start-qwen36-27b-unsloth-nvfp4-mtp-gguf-server.bat
```

35B A3B quick path:

```bat
cd scripts\localai\qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf
download-qwen36-35b-a3b-unsloth-nvfp4.bat
convert-qwen36-35b-a3b-unsloth-nvfp4-to-gguf.bat
install-hermes-qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf.bat

set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
start-qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf-server.bat
```

35B A3B Fast quick path:

```bat
cd scripts\localai\qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf
download-qwen36-35b-a3b-unsloth-nvfp4-fast.bat
convert-qwen36-35b-a3b-unsloth-nvfp4-fast-to-gguf.bat
install-llama-b10068-win-cuda13.bat
install-hermes-qwen36-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.bat
start-qwen36-35b-a3b-unsloth-nvfp4-fast-mtp-gguf-server.bat
```

The Fast source is
[unsloth/Qwen3.6-35B-A3B-NVFP4-Fast](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-NVFP4-Fast).
Unlike the earlier mixed checkpoint, it stores every expert layer as native
NVFP4. Its converted file is
`qwen3.6-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.gguf`; the Hermes alias is
`qwen36-35b-a3b-unsloth-nvfp4-fast-mtp-gguf` on port 39202.

On Windows 11, RTX 5090, llama.cpp b10068, 200k context, q4_0 target/draft KV,
no-thinking, and `draft-mtp n=2`, the Fast GGUF decoded at **135.23 tok/s**
for 8,907 prompt tokens and **84.08 tok/s** for 174,590 prompt tokens. Prefill
took **2.16s** and **52.84s**; MTP acceptance was **60.7%** and **59.7%**.
The loaded 200k server used about **25.1 GiB** of the 5090's 32 GB. The smaller
all-NVFP4 conversion did not reproduce Unsloth's vLLM-oriented Fast throughput
gain in native llama.cpp; the earlier mixed 35B GGUF remains faster in this
specific single-request benchmark.

Both launchers use 200k context, q4_0 target/draft KV caches, `draft-mtp n=2`,
and no-thinking. Hermes aliases are `qwen36-27b-unsloth-nvfp4-mtp-gguf` on
port 39196 and `qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf` on port 39197.

Download the converted native GGUFs from Hugging Face, not GitHub:

- [neko-legends/Qwen3.6-27B-NVFP4-MTP-GGUF](https://huggingface.co/neko-legends/Qwen3.6-27B-NVFP4-MTP-GGUF)
- [neko-legends/Qwen3.6-35B-A3B-NVFP4-MTP-GGUF](https://huggingface.co/neko-legends/Qwen3.6-35B-A3B-NVFP4-MTP-GGUF)

### Qwen3.6 27B Q4_K_M with DFlash Q8_0

Native Windows CUDA profile for [spiritbuun/Qwen3.6-27B-DFlash-GGUF](https://huggingface.co/spiritbuun/Qwen3.6-27B-DFlash-GGUF). The 1.85 GB `dflash-draft-3.6-q8_0.gguf` is a speculative drafter, not the full model; this profile pairs it with the base `Qwen3.6-27B-Q4_K_M.gguf` target.

```bat
cd scripts\localai\qwen36-27b-dflash-gguf
download-qwen36-27b-q4-k-m-target.bat
download-qwen36-27b-dflash-q8-0.bat
bootstrap-cuda-13.3-portable.bat
build-buun-dflash-sm120-runtime.bat
install-hermes-qwen36-27b-q4-k-m-dflash-q8-0.bat
start-qwen36-27b-q4-k-m-dflash-q8-0-server.bat
```

The launcher uses a 200,000-token target context, a 256-token draft context,
q4_0 KV caches, no thinking, and the fork's tuned full 15-token DFlash
horizon. It runs at `http://127.0.0.1:39201/v1`; the Hermes alias is
`qwen36-27b-q4-k-m-dflash-q8-0`. The build is pinned to fork commit
`34501c5` and CUDA 13.3 for Blackwell `120a`. The portable CUDA bootstrap
uses NVIDIA's hash-verified redistributable archives and does not replace the
installed display driver. Both the target and drafter are explicitly pinned
to the RTX 5090 (`CUDA0`) and fully offloaded. This explicit draft-device pin
is required on mixed-GPU hosts; otherwise the fork may initialize the drafter
on another CUDA device. The benchmark script aborts before inference unless it
sees complete `65/65` target and `6/6` draft layer offload on CUDA0. Its adaptive
GPU-only policy disables unhelpful drafting and hidden capture per request;
generation remains on the RTX 5090 and never falls back to CPU model layers.

#### DFlash credits and provenance

- Target GGUF: [unsloth/Qwen3.6-27B-GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF), file `Qwen3.6-27B-Q4_K_M.gguf`.
- DFlash drafter: [spiritbuun/Qwen3.6-27B-DFlash-GGUF](https://huggingface.co/spiritbuun/Qwen3.6-27B-DFlash-GGUF), file `dflash-draft-3.6-q8_0.gguf`.
- Upstream runtime fork: [spiritbuun/buun-llama-cpp](https://github.com/spiritbuun/buun-llama-cpp), pinned here to commit `34501c5`.
- This repository supplies the Windows CUDA 13.3 build automation, runtime patches, CUDA0 placement, adaptive bypass, Hermes integration, and reproducible benchmarks.

The two GGUF files are downloaded unchanged from their original Hugging Face
repositories. The performance work modifies the serving runtime and launch
configuration, not the model weights.

### Ternary-Bonsai 27B with DSpark Q4_1

Native Windows CUDA profile for [prism-ml/Ternary-Bonsai-27B-gguf](https://huggingface.co/prism-ml/Ternary-Bonsai-27B-gguf). It uses the quality-oriented `Ternary-Bonsai-27B-Q2_0.gguf` target and the recommended `Ternary-Bonsai-27B-dspark-Q4_1.gguf` speculative drafter.

```bat
cd scripts\localai\ternary-bonsai-27b-gguf
build-prism-llamacpp-sm120-runtime.bat
download-ternary-bonsai-27b-dspark-q4-1.bat
install-hermes-ternary-bonsai-27b-dspark-q4-1.bat
start-ternary-bonsai-27b-dspark-q4-1-server.bat
```

The RTX 5090 build compiles PrismML commit `62061f9` for Blackwell `120a`. DSpark mode uses a 16,384-token server context, q4_0 target/draft KV caches, `draft-dspark n=4`, and no reasoning output. The included target-only launcher supports the full 262,144-token context; current DSpark staging is not practical at 200K on a 32 GB GPU. Hermes model alias: `ternary-bonsai-27b-dspark-q4-1` on port `39199`.

Here, **target-only** means that `Ternary-Bonsai-27B-Q2_0.gguf`, the actual language model, generates every token normally. `Ternary-Bonsai-27B-dspark-Q4_1.gguf` is only an optional drafter: it proposes four-token blocks for the Q2_0 target to verify and cannot run by itself.

DSpark did not load at 200K because the current PrismML server stages intermediate target states for the entire configured context in one physical draft batch. At `ctx=262144`, that path raised the draft batch to 262,148 positions and attempted a roughly **161 GB CUDA compute allocation**. The target, weights, and q4_0 KV cache themselves fit in about **13.2 GiB**, so this is a DSpark staging implementation limit rather than the model running out of ordinary KV-cache VRAM. The provided full-context launcher therefore disables DSpark.

### ThinkingCap Qwen3.6 27B Q4_K_M

Native Windows llama.cpp profile for [bottlecapai/ThinkingCap-Qwen3.6-27B-GGUF](https://huggingface.co/bottlecapai/ThinkingCap-Qwen3.6-27B-GGUF), using the upstream `ThinkingCap-Qwen3.6-27B-Q4_K_M.gguf`. The GGUF already includes an MTP head, so no conversion or separate draft model is needed.

```bat
cd scripts\localai\thinkingcap-qwen36-27b-gguf
download-thinkingcap-qwen36-27b-q4-k-m.bat
install-hermes-thinkingcap-qwen36-27b-q4-k-m.bat

set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
start-thinkingcap-qwen36-27b-q4-k-m-server.bat
```

The launcher uses 200k context, q4_0 target/draft KV caches, `draft-mtp n=4`, and no-thinking by default. Hermes model alias: `thinkingcap-qwen36-27b-q4-k-m` on port `39198`.

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

## Model Storage

The launchers store downloaded and converted models outside the repo checkout,
under the checkout parent's shared cache:

```text
<checkout-parent>\.local-model-cache\
```

For this checkout at `D:\forPublic\nvidia-local-llm-profiles`, that resolves to:

```text
D:\forPublic\.local-model-cache\
```

Examples:

```text
D:\forPublic\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4\
D:\forPublic\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4-MTP-GGUF\qwen3.6-27b-nvfp4-mtp-gguf.gguf
D:\forPublic\.local-model-cache\nvidia\Qwen3.6-35B-A3B-NVFP4-MTP-GGUF\qwen3.6-35b-a3b-nvfp4-mtp.gguf
D:\forPublic\.local-model-cache\unsloth\Qwen3.6-35B-A3B-NVFP4-Fast-MTP-GGUF\qwen3.6-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.gguf
D:\forPublic\.local-model-cache\Jackrong\Qwopus3.6-35B-A3B-Coder-MTP-GGUF\
D:\forPublic\.local-model-cache\deepreinforce-ai\Ornith-1.0-35B-GGUF\
D:\forPublic\.local-model-cache\prism-ml\Ternary-Bonsai-27B-gguf\
D:\forPublic\.local-model-cache\spiritbuun\Qwen3.6-27B-DFlash-GGUF\
```

Most scripts also accept environment overrides such as `MODEL_DIR`,
`MODEL_PATH`, `SOURCE_MODEL_DIR`, `OUT_DIR`, `OUTFILE`, `LLAMA_DIR`, and
`LLAMA_CPP_SRC` when you want to use a different disk.

---

## RTX 5090 Benchmark Results

**GPU:** RTX 5090 32GB - **Driver:** 610.62 - **Dates:** 2026-06-22 to
2026-07-19

Headline chart: native Windows llama.cpp GGUF endpoints only, using the checked-in
BookContext 10k and 200k prompts with 1024 generated tokens. Bars are llama.cpp
generation/decode tok/s after prompt prefill; prompt prefill seconds are labeled
separately. Docker/vLLM and manual UI observations are kept in
`results/rtx-5090/README.md`.

![RTX 5090 native llama.cpp long-context comparison](assets/images/rtx-5090-qwen35-moe-vs-qwopus.png)

Qwen3.6 27B Q4_K_M with the recommended Q8_0 DFlash drafter against the
native Windows field, benchmark snapshot dated July 14, 2026:

![Qwen3.6 27B DFlash versus RTX 5090 native llama.cpp field, July 14 2026](assets/images/qwen36-27b-dflash-vs-rtx-5090-field-20260714.png)

The focused before/after view shows the effect of the Windows runtime and
placement fixes. On the same 8,907-token BookContext fixture, decode increased
from **22.50 tok/s** to **57.53 tok/s**: **2.56x faster (+156%)**.

![Qwen3.6 27B DFlash Windows before and after runtime fixes, July 14 2026](assets/images/qwen36-27b-dflash-windows-before-after-20260714.png)

- RTX 5090, Windows 11, buun llama.cpp commit `34501c5`, CUDA 13.3 `sm_120a`,
  `ctx=200000`, q4_0 target/draft KV, no thinking, and DFlash horizon 15.
- The corrected 8,907-token run measured **57.53 decode tok/s**, **5.39s**
  prefill, and **43.87 full-request tok/s**. Both target (`65/65`) and draft
  (`6/6`) were fully offloaded to CUDA0.
- Low-acceptance BookContext triggered the GPU-only adaptive bypass after four
  DFlash cycles. A 37-token Python coding probe stayed on DFlash and measured
  **149.51 decode tok/s** with **73.74%** draft acceptance.
- The speedup came from pinning both models to CUDA0, fully offloading all
  target and draft layers, repairing per-slot acceptance feedback, bypassing
  speculative work when acceptance is poor, and disabling unnecessary hidden
  capture after that bypass. The benchmark now fails before prompting if it
  detects partial offload or CUDA1 placement.
- The 200K bar remains the historical **14.05 tok/s** `ngld=1` diagnostic. It
  is labeled historical in the chart and was intentionally not rerun while
  the staged 1K -> 10K validation was being completed.
- Curated results: `results/rtx-5090/qwen36-27b-dflash-benchmark-20260714.csv`.
- Tuning history: `results/rtx-5090/qwen36-27b-dflash-tuning-20260714.csv`.

Ternary-Bonsai 27B target and Q4_1 DSpark comparison against the full native field, benchmark snapshot dated July 14, 2026:

![Ternary-Bonsai 27B and DSpark versus RTX 5090 native llama.cpp field, July 14 2026](assets/images/ternary-bonsai-27b-vs-rtx-5090-field-20260714.png)

- RTX 5090, Windows 11, PrismML llama.cpp commit `62061f9`, locally compiled for CUDA 12.8 `sm_120a`, q4_0 KV, reasoning budget 0.
- Target-only decoded at **83.5 tok/s** for the 8,907-token fixture and **19.9 tok/s** for the 174,590-token fixture. Prefill took **2.9s** and **125.2s** respectively.
- A fresh isolated 200K confirmation measured **19.90 tok/s** after the original **19.85 tok/s** run. Both figures use llama.cpp's 1,024-token `eval time`; the separate 125.2-second prompt prefill is not included.
- DSpark Q4_1 at `ctx=16384`, `n=4` decoded at **76.5 tok/s** for 741 generated tokens, with **25.1%** token acceptance. It was about 8% slower than target-only on this workload.
- Current DSpark server code stages the full context in one physical batch. A 262K attempt requested a 161 GB CUDA buffer, so the 200K result is target-only; the DSpark launcher conservatively advertises 16,384 tokens to Hermes.
- Curated results: `results/rtx-5090/ternary-bonsai-27b-benchmark-20260714.csv`.

ThinkingCap Qwen3.6 27B Q4_K_M against the full native GGUF field, benchmark snapshot dated July 14, 2026:

![ThinkingCap Qwen3.6 27B Q4_K_M versus RTX 5090 native llama.cpp field, July 14 2026](assets/images/thinkingcap-qwen36-27b-vs-rtx-5090-field-20260714.png)

- RTX 5090, Windows 11, llama.cpp b9851, `ctx=200000`, q4_0 target/draft KV,
  no-thinking, `draft-mtp n=4`, and one 1024-token measured completion.
- The upstream Q4_K_M GGUF already exposes its MTP block (`nextn_predict_layers=1`);
  it decoded at **90.9 tok/s** for the 8,907-token fixture and **49.4 tok/s**
  for the 174,590-token fixture.
- MTP acceptance was **49.9%** / mean length **2.99** at 10k and **46.9%** /
  **2.87** at 200k. The model used **22.0 GiB** after each request and finished
  at **52 C** / **70 C**.
- A fresh isolated 200k rerun of Qwopus3.6 27B Coder Q5 on the same BookContext
  fixture measured **48.0 tok/s** with `ngram-mod,draft-mtp n=2`, narrowly behind
  ThinkingCap's **49.4 tok/s**. This replaces the prior approximate **70.2 tok/s**
  Qwopus 27B chart row.
- Curated results: `results/rtx-5090/thinkingcap-qwen36-27b-q4-k-m-benchmark-20260714.csv`.

Fresh native Windows source comparison for NVIDIA and Unsloth NVFP4 checkpoints:

![NVIDIA versus Unsloth Qwen3.6 NVFP4 native GGUF comparison](assets/images/qwen36-unsloth-nvfp4-native-comparison.png)

- RTX 5090, Windows 11, llama.cpp b9851, `ctx=200000`, `draft-mtp n=2`,
  no-thinking, q4_0 target/draft KV, one 1024-token measured completion.
- Both rows in each panel use the same BookContext source input: 8,907 actual
  prompt tokens for the 10k target and 174,590 for the 200k target.
- Unsloth 27B decoded at **72.8 vs 69.0 tok/s** at 10k and **44.1 vs 42.2** at
  200k, while using **26.1 vs 30.8 GiB** after request. It also finished at
  **46 C vs 52 C** at 10k and **60 C vs 61 C** at 200k.
- The 35B A3B variants were effectively tied, with a slight Unsloth edge:
  **151.2 vs 150.9 tok/s** at 10k and **93.2 vs 90.2** at 200k. Unsloth used
  about 2.1 GiB more VRAM but finished **3 C lower** at 10k and **2 C lower**
  at 200k.
- Curated results: `results/rtx-5090/qwen36-unsloth-nvfp4-native-comparison-20260710.csv`.

llama.cpp build check for `neko-legends/Qwen3.6-35B-A3B-NVFP4-MTP-GGUF`:

![llama.cpp b9761 vs b9851 Qwen3.6 NVFP4 MTP GGUF decode comparison](assets/images/qwen36-llamacpp-b9761-vs-b9851.png)

NVIDIA Qwen3.6 27B NVFP4 Windows GGUF vs Docker check:

![Qwen3.6 27B NVFP4 on RTX 5090 Windows, native GGUF versus Docker vLLM](assets/images/qwen36-27b-nvfp4-mtp-vs-no-mtp.png)

- Source snapshot: `nvidia/Qwen3.6-27B-NVFP4`; local GGUF:
  `qwen3.6-27b-nvfp4-mtp-gguf.gguf`.
- The source snapshot has `mtp_num_hidden_layers=1` and `mtp.layers.0.*`
  tensors. The conversion keeps that MTP block in the GGUF.
- On RTX 5090 at `ctx=200000`, no-thinking, q4 target/draft KV, llama.cpp
  b9851, `draft-mtp` n=2 improved decode from **48.2 -> 67.9 tok/s** at 10k
  and **32.9 -> 41.3 tok/s** at 200k.
- The MTP run used about **30.8 GiB** after request, versus **29.2 GiB** for the
  no-MTP baseline. Because of that tight headroom, this repo advertises the
  local 5090 profile at **200k context**, not the model card's maximum 262k.
- Curated data:
  `results/rtx-5090/qwen36-27b-nvfp4-gguf-mtp-comparison-20260703.csv`.

Max-context fit check for `qwen3.6-27b-nvfp4-mtp-gguf.gguf` on RTX 5090:

| Mode | Context | Result | Peak VRAM | Minimum free VRAM | Notes |
| --- | ---: | --- | ---: | ---: | --- |
| `draft-mtp n=2` | 220k | 200k prompt fixture passed | 32,088 MiB | 103 MiB | Highest real-prompt-tested MTP context |
| `draft-mtp n=2` | 228.5k | Loaded, then failed real prompt | 32,162 MiB | 29 MiB | Loads-only edge; not usable for long prompts |
| `draft-mtp n=2` | 229k+ | Failed to load | - | - | Failed while creating MTP context |
| No MTP | 262,144 | 200k prompt fixture passed | 31,248 MiB | 943 MiB | Full context fits only without speculative MTP |

MTP costs extra VRAM: at the 200k throughput benchmark it used about **1.6 GiB**
more than the no-MTP path. If the RTX 5090 is also driving your desktop or other
apps, use the default **200k** profile or lower it further with `CTX_SIZE`;
`220k` is an aggressive fit-check setting, not the everyday default.

- Context fit data:
  `results/rtx-5090/qwen36-27b-nvfp4-mtp-gguf-context-fit-20260703.csv`.

Windows 11 Docker/vLLM baseline for the original `nvidia/Qwen3.6-27B-NVFP4`
safetensors checkpoint. vLLM is the recommended runtime for NVIDIA ModelOpt
NVFP4 safetensors, but this Windows 11 + Docker Desktop run is a compatibility
baseline, not the expected best-performance Linux path:

- Stack: Windows 11 host, Docker Desktop, `vllm/vllm-openai:nightly`
  (`0.23.1rc1.dev301+g04c2a8dea`), ModelOpt NVFP4, fp8 KV, no MTP,
  `ctx=200000`.
- vLLM reported `223,880` GPU KV-cache tokens and `1.12x` maximum concurrency
  for 200k requests. Startup reached the OpenAI endpoint after roughly 8
  minutes with FlashInfer autotune disabled.
- 10k warmed request: **32.1 full-wall tok/s**; engine log showed about
  **34.8 generation tok/s** after prompt/JIT.
- 200k request: **9.24 full-wall tok/s**; engine log showed about
  **30.9 generation tok/s** after prompt prefill.
- vLLM logged that this RTX 5090 run used weight-only FP4 compression through
  Marlin rather than native FP4 compute, so this Docker result is not comparable
  to RTX PRO 6000/GB-class vLLM NVFP4 screenshots or native Linux vLLM
  deployments.

- Latest checked build: **llama.cpp b9851** (`0eca4d490`), CUDA 13.3 Windows
  release.
- Same GGUF, RTX 5090, `draft-mtp` n=2, no-thinking, q4 target/draft KV.
- Decode-only `slot print_timing` improved from **146.8 -> 152.7 tok/s** at
  10k, **88.5 -> 90.4 tok/s** at 200k, and **68.1 -> 69.2 tok/s** at the
  300k-target / 262k-cap edge.
- The 300k target prompt tokenized to **261,960 prompt tokens**. llama.cpp
  capped the slot at **262,144** and stopped truncated after **183 generated
  tokens**, so that row is a max-context stress check rather than a normal
  1024-token completion.
- This chart intentionally omits wall-rate numbers; it uses llama.cpp
  decode/generation timing only.

Additional model notes:

- `Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF` Q4_K_M and Q5_K_M loaded
  natively at `ctx=200000` (`n_ctx=200192`) with q4 target/draft KV,
  request-level no-thinking, Q5 on pure `draft-mtp`, and Q4 on
  `ngram-mod,draft-mtp`.
- No-thinking proof: on the same server, an auto request produced
  `reasoning_content`, while a request with
  `chat_template_kwargs.enable_thinking=false` produced normal content without a
  reasoning block. The `Local 5090` router now injects that request default for
  Qwopus35.
- 10k reference prompt: **148.6 decode tok/s**, 111.8 full-wall tok/s after
  2.1s prefill.
- 200k reference prompt: **102.5 decode tok/s**, 15.5 full-wall tok/s after
  55.5s prefill.
- Q5_K_M spec-type check: pure `draft-mtp` n=2 beat the previous
  `ngram-mod,draft-mtp` n=2 profile at 200k (**102.5** vs **100.0** decode
  tok/s), while landing essentially tied at 10k (**148.6** vs **149.0**).
- Q5_K_M MTP depth check: `--spec-draft-n-max 3` improves the 10k generation
  check to **153.8 decode tok/s**, but the 200k generation check drops to
  **94.6 decode tok/s**. The chart keeps Q5 on pure `draft-mtp` n=2 because
  this comparison is anchored on the long-context profile rather than
  per-context cherry-picks.
- Q4_K_M no-thinking result: **181.0 decode tok/s** at 10k and **91.2 decode
  tok/s** at 200k. A Q4 n=3 MTP trial was slower than n=2 on the 10k check, so
  the chart uses `--spec-draft-n-max 2`.
- Prompt prefill is the model reading the input prompt into KV cache. No-thinking
  prevents generated reasoning blocks, but it does not skip reading a 200k
  prompt; the fresh 200k run still processed 166,199 new prompt tokens after
  reusing the 10k prefix from the previous request.
- Peak observed memory after request for the current Q5 profile: 27.0 GiB at
  10k and 27.6 GiB at 200k
  from the recorded `nvidia-smi` MiB fields.

The 10k and 200k reference prompts are checked in at
`benchmarks/prompts/book-context-10k.txt` and
`benchmarks/prompts/book-context-200k.txt`. The 300k-target stress prompt is
checked in at `benchmarks/prompts/book-context-300k.txt`. Their SHA256 values are
`785c5b31d1ce77612431b1289c0a097ed51ab1a6d4a07bccfb7a70f59df55f94` and
`a794ca243983eb3387bec6728db4b0c72a99ee2a98cfee7223269708e4ae228c`, and
`5e3a5f9c15da85d938993ef0c80153d26ba405a13689447fd7082d23355ca4ba`.

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

Or NVIDIA Qwen3.6 27B NVFP4 MTP GGUF:

```bat
scripts\localai\qwen36-27b-nvfp4-gguf\start-qwen36-27b-nvfp4-gguf-server.bat
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
- `qwen36-27b-nvfp4-mtp-gguf` routes to `http://127.0.0.1:39195/v1`
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
python scripts\benchmarks\render-qwen27-nvfp4-mtp-comparison-chart.py
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
    qwen36-27b-nvfp4-gguf/          NVIDIA Qwen 27B NVFP4 MTP GGUF launcher
    qwen36-27b-dflash-gguf/         Qwen 27B Q4_K_M + DFlash Q8_0 launcher
    thinkingcap-qwen36-27b-gguf/    ThinkingCap 27B Q4_K_M MTP GGUF launcher
    ternary-bonsai-27b-gguf/     Ternary-Bonsai 27B Q2_0 + DSpark launcher
    qwen36-35b-a3b-mtp-gguf/        Unsloth Qwen 35B GGUF launcher
    qwen36-35b-a3b-nvfp4-mtp-gguf/  NVIDIA Qwen 35B NVFP4 MTP GGUF launcher
    ornith-1.0-35b-gguf/            Ornith 35B GGUF launcher
  vllm/
    aeon-ornith-1.0-35b-nvfp4/       AEON Ornith NVFP4 Docker vLLM launcher
    aeon-qwen36-27b-multimodal-nvfp4-mtp-xs/  Docker vLLM launcher
    qwen36-27b-nvfp4/                 NVIDIA Qwen 27B NVFP4 Docker vLLM launcher
    qwen36-35b-a3b-nvfp4/            NVIDIA MoE NVFP4 two-point bench
  benchmarks/
    bench-context-ladder.ps1         full context ladder sweep
    bench-openai-chat-endpoint.ps1   single endpoint benchmark
    download-hf-artifact.py          HF download helper
    render-aeon-ornith-windows-comparison-chart.py  AEON Ornith chart
    render-qwen35-moe-comparison-chart.py     native llama.cpp 35B comparison chart
    render-qwen36-27b-dflash-comparison-chart.py  DFlash field chart
    render-qwen36-27b-dflash-before-after-chart.py  DFlash tuning chart
docs/
  models/qwopus3.6-27b-coder-mtp-gguf.md   model notes
  models/aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.md   AEON vLLM notes
  models/qwen36-27b-nvfp4-mtp-gguf.md       NVIDIA Qwen 27B MTP GGUF notes
  models/qwen36-35b-a3b-nvfp4-mtp-gguf.md   NVIDIA GGUF notes
  hardware/rtx-5090-power-and-thermal.md    GPU tuning notes
  integrations/hermes-desktop.md            Hermes wiring guide
results/
  rtx-5090/                                 benchmark CSVs + README
```
