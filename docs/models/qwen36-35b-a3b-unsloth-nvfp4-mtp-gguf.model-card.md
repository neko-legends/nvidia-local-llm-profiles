---
license: apache-2.0
base_model:
- unsloth/Qwen3.6-35B-A3B-NVFP4
base_model_relation: quantized
library_name: llama.cpp
pipeline_tag: text-generation
tags:
- gguf
- llama.cpp
- nvfp4
- fp8
- mtp
- speculative-decoding
- qwen3.6
- qwen35moe
- blackwell
- rtx-5090
- windows
- unsloth
---

<div style="font-family: Inter, ui-sans-serif, system-ui, sans-serif; border: 1px solid #3a2a1f; background: #0f0f13; border-radius: 16px; overflow: hidden; margin: 0 0 28px 0;">
  <div style="padding: 14px 18px; background: linear-gradient(90deg, #1a120d 0%, #2b1708 100%); border-bottom: 1px solid rgba(255,122,26,0.35); color: #ffd7ad; font-weight: 900;">RTX 5090 Windows native GGUF comparison</div>
  <img src="https://huggingface.co/neko-legends/Qwen3.6-35B-A3B-NVFP4-MTP-GGUF/resolve/main/qwen36-unsloth-nvfp4-native-comparison.png" alt="NVIDIA and Unsloth Qwen3.6 NVFP4 native GGUF benchmark comparison" style="display:block; width:100%; border:0;" />
</div>

# Qwen3.6 35B A3B Unsloth NVFP4 MTP GGUF

Native llama.cpp conversion of [unsloth/Qwen3.6-35B-A3B-NVFP4](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-NVFP4). This is a separate artifact from the existing NVIDIA-source file in this repository.

## File

| File | Source | Format |
| --- | --- | --- |
| `qwen3.6-35b-a3b-unsloth-nvfp4-mtp-gguf.gguf` | Unsloth NVFP4 | Native NVFP4 expert FFNs, source FP8 tensors stored as Q8_0, bundled MTP preserved |

Size: 24.34 GiB. SHA256: `923AB9A153CB21BB78ADB5A98C4193C034F940D56D83A90714B3F6881DA6FB92`.

The source checkpoint uses a mixed compressed-tensors layout. The conversion keeps packed NVFP4 expert tensors native and stores the source FP8 weights as Q8_0 for practical 200k-context headroom on an RTX 5090. The MTP block remains available to llama.cpp through `draft-mtp`.

## RTX 5090 Result

Windows 11, RTX 5090, llama.cpp b9851, `ctx=200000`, q4_0 target/draft KV, `draft-mtp n=2`, no-thinking, identical BookContext prompt fixture, and one measured 1024-token completion.

| Source | 10k wall tok/s | 200k wall tok/s | VRAM after | Temperature after |
| --- | ---: | ---: | ---: | ---: |
| NVIDIA source GGUF | 110.0 | 16.18 | 24.6 GiB | 44 C / 52 C |
| Unsloth source GGUF | 110.3 | 16.52 | 26.7 GiB | 41 C / 50 C |

The 35B A3B variants are effectively tied, with a small Unsloth edge in this run. The Unsloth conversion finished 3 C cooler at 10k and 2 C cooler at 200k, while using about 2.1 GiB more VRAM.

## Quick Start

```bash
llama-server \
  --model qwen3.6-35b-a3b-unsloth-nvfp4-mtp-gguf.gguf \
  --alias qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf \
  --host 0.0.0.0 \
  --port 39197 \
  --device CUDA0 \
  --gpu-layers all \
  --gpu-layers-draft all \
  --ctx-size 200000 \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  --cache-type-k-draft q4_0 \
  --cache-type-v-draft q4_0 \
  --flash-attn on \
  --parallel 1 \
  --cont-batching \
  --jinja \
  --reasoning off \
  --spec-type draft-mtp \
  --spec-draft-n-max 2 \
  --spec-draft-p-min 0.0
```

## Companion Scripts

Windows download, conversion, Hermes setup, launcher, and benchmark scripts are in [neko-legends/nvidia-local-llm-profiles](https://github.com/neko-legends/nvidia-local-llm-profiles/tree/master/scripts/localai/qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf). The repository also includes the temporary mixed-NVFP4 llama.cpp converter compatibility patch used for this release.

Apache 2.0, inherited from the Unsloth source release.
