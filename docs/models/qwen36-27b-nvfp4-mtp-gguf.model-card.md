---
license: apache-2.0
base_model:
- nvidia/Qwen3.6-27B-NVFP4
base_model_relation: quantized
library_name: llama.cpp
pipeline_tag: text-generation
tags:
- gguf
- llama.cpp
- nvfp4
- mtp
- speculative-decoding
- qwen3.6
- qwen27
- blackwell
- rtx-5090
- windows
- local-llm
- neko-legends
---

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; border: 1px solid #3a2a1f; background: #0f0f13; border-radius: 16px; overflow: hidden; margin: 0 0 28px 0; box-shadow: 0 20px 48px rgba(0,0,0,0.24);">
  <div style="padding: 14px 18px; background: linear-gradient(90deg, #1a120d 0%, #2b1708 100%); border-bottom: 1px solid rgba(255,122,26,0.35); color: #ffd7ad; font-weight: 950;">RTX 5090 native llama.cpp benchmark chart</div>
  <a href="https://huggingface.co/neko-legends/Qwen3.6-27B-NVFP4-MTP-GGUF/blob/main/qwen36-27b-nvfp4-mtp-vs-no-mtp.png" target="_blank" style="display:block; background:#050507;">
    <img src="https://huggingface.co/neko-legends/Qwen3.6-27B-NVFP4-MTP-GGUF/resolve/main/qwen36-27b-nvfp4-mtp-vs-no-mtp.png" alt="RTX 5090 native llama.cpp Qwen3.6 27B NVFP4 MTP versus no-MTP benchmark chart" style="display:block; width:100%; border:0;" />
  </a>
</div>

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; border: 1px solid #2f2118; border-radius: 18px; overflow: hidden; background: #0b0b0f; box-shadow: 0 20px 48px rgba(0,0,0,0.26); margin: 0 0 28px 0;">
  <div style="padding: 30px 28px 24px 28px; background: radial-gradient(circle at 8% 0%, rgba(255,122,26,0.34), transparent 34%), radial-gradient(circle at 92% 10%, rgba(255,184,107,0.18), transparent 26%), linear-gradient(135deg, #050507 0%, #111116 54%, #1f1209 100%); border-bottom: 1px solid rgba(255,122,26,0.35);">
    <div style="display: flex; flex-wrap: wrap; gap: 14px; align-items: center; justify-content: space-between;">
      <div>
        <div style="font-size: 11px; font-weight: 900; color: #ffb86b; letter-spacing: 1.8px; text-transform: uppercase;">Neko Legends local inference release</div>
        <h1 style="margin: 8px 0 0 0; color: #fff7ed; font-size: 30px; line-height: 1.12; font-weight: 950; border: 0;">Qwen3.6-27B-NVFP4-MTP-GGUF</h1>
      </div>
      <div style="background: rgba(255,122,26,0.14); border: 1px solid rgba(255,122,26,0.72); color: #ffd7ad; font-size: 12px; font-weight: 900; padding: 8px 12px; border-radius: 999px;">RTX 5090 validated</div>
    </div>
    <p style="margin: 14px 0 0 0; max-width: 900px; color: #d6d3d1; font-size: 14px; line-height: 1.7;">
      A native <code style="color:#ffb86b;">llama.cpp</code> GGUF conversion of NVIDIA's Qwen3.6 27B NVFP4 release. The GGUF keeps the source MTP block so it can run with <code style="color:#ffb86b;">draft-mtp</code> speculative decoding on recent builds.
    </p>
  </div>

  <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(155px, 1fr)); gap: 1px; background: #2f2118;">
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Format</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">GGUF</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Quant</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">NVFP4</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Spec decode</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">draft-mtp</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Bench ctx</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">200k</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Artifact</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">26.29 GiB</b></div>
  </div>
</div>

## Quick Start

Repository: [`neko-legends/Qwen3.6-27B-NVFP4-MTP-GGUF`](https://huggingface.co/neko-legends/Qwen3.6-27B-NVFP4-MTP-GGUF)

Use `qwen3.6-27b-nvfp4-mtp-gguf.gguf`. This is the NVFP4 GGUF with the source MTP block preserved.

```bash
llama-server \
  --model qwen3.6-27b-nvfp4-mtp-gguf.gguf \
  --alias qwen36-27b-nvfp4-mtp-gguf \
  --host 0.0.0.0 \
  --port 39195 \
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
  --metrics \
  --slots \
  --reasoning off \
  --spec-type draft-mtp \
  --spec-draft-n-max 2 \
  --spec-draft-p-min 0.0
```

## File

| File | Size | SHA256 |
| --- | ---: | --- |
| `qwen3.6-27b-nvfp4-mtp-gguf.gguf` | 28,230,538,624 bytes / 26.29 GiB | `5DECEF7638A9324664010695A49BA1C6EABD18FCFC1616B77C0AFF97B412A233` |

## RTX 5090 Benchmark

Windows native `llama.cpp` b9851, RTX 5090, CUDA, q4 target KV, no-thinking request mode, 1024 generated tokens, temperature 0, seed 1234. The chart uses decode-only `llama.cpp` generation timing; full request tok/s includes prompt processing.

| Mode | Prompt | Prompt tokens | Full request tok/s | Decode tok/s | Prompt read | VRAM after | MTP acceptance |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| No MTP | 10k | 8,907 | 42.1 | 48.2 | 2.9s | 29.2 GiB | - |
| draft-mtp n=2 | 10k | 8,907 | 55.9 | 67.9 | 3.1s | 30.8 GiB | 66.9% |
| No MTP | 200k | 174,590 | 6.7 | 32.9 | 121.4s | 29.2 GiB | - |
| draft-mtp n=2 | 200k | 174,590 | 6.5 | 41.3 | 131.8s | 30.8 GiB | 68.3% |

Benchmark prompt files are in this project:

| File | SHA256 |
| --- | --- |
| `benchmarks/prompts/book-context-10k.txt` | `785C5B31D1CE77612431B1289C0A097ED51AB1A6D4A07BCCFB7A70F59DF55F94` |
| `benchmarks/prompts/book-context-200k.txt` | `A794CA243983EB3387BEC6728DB4B0C72A99EE2A98CFEE7223269708E4AE228C` |

## Conversion

The source snapshot is [`nvidia/Qwen3.6-27B-NVFP4`](https://huggingface.co/nvidia/Qwen3.6-27B-NVFP4). Convert with a recent `llama.cpp` checkout:

```bash
python convert_hf_to_gguf.py \
  /path/to/Qwen3.6-27B-NVFP4 \
  --outfile qwen3.6-27b-nvfp4-mtp-gguf.gguf \
  --outtype auto \
  --model-name nvidia-Qwen3.6-27B-NVFP4-MTP
```

No `--no-mtp` flag was used. The downloaded NVIDIA source snapshot includes the `mtp.*` tensors, and the exported GGUF keeps them for `draft-mtp`.

## Local Scripts

The companion Windows helper scripts live in [`neko-legends/nvidia-local-llm-profiles`](https://github.com/neko-legends/nvidia-local-llm-profiles):

```bat
scripts\localai\qwen36-27b-nvfp4-gguf\download-qwen36-27b-nvfp4.bat
scripts\localai\qwen36-27b-nvfp4-gguf\convert-qwen36-27b-nvfp4-to-gguf.bat
scripts\localai\qwen36-27b-nvfp4-gguf\start-qwen36-27b-nvfp4-gguf-server.bat
scripts\localai\qwen36-27b-nvfp4-gguf\install-hermes-qwen36-27b-nvfp4-gguf.bat
```

License is Apache 2.0, inherited from the NVIDIA source release.
