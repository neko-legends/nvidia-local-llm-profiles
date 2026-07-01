---
license: mit
license_link: https://huggingface.co/deepreinforce-ai/Ornith-1.0-35B/blob/main/LICENSE
base_model:
- AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4
- deepreinforce-ai/Ornith-1.0-35B
base_model_relation: quantized
library_name: llama.cpp
pipeline_tag: text-generation
tags:
- gguf
- llama.cpp
- nvfp4
- mtp
- speculative-decoding
- blackwell
- rtx-5090
- qwen3_5_moe
- moe
- mixture-of-experts
- reasoning
- thinking
- coding
- agentic
- uncensored
- abliterated
- aeon
- aeon-7
- ornith
- 35b
- local-llm
- windows
- neko-legends
---

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; border: 1px solid #2f2118; border-radius: 18px; overflow: hidden; background: #0b0b0f; box-shadow: 0 20px 48px rgba(0,0,0,0.26); margin: 0 0 28px 0;">
  <div style="padding: 30px 28px 24px 28px; background: radial-gradient(circle at 8% 0%, rgba(255,122,26,0.34), transparent 34%), radial-gradient(circle at 92% 10%, rgba(255,184,107,0.18), transparent 26%), linear-gradient(135deg, #050507 0%, #111116 54%, #1f1209 100%); border-bottom: 1px solid rgba(255,122,26,0.35);">
    <div style="display: flex; flex-wrap: wrap; gap: 14px; align-items: center; justify-content: space-between;">
      <div>
        <div style="font-size: 11px; font-weight: 900; color: #ffb86b; letter-spacing: 1.8px; text-transform: uppercase;">Neko Legends local inference release</div>
        <h1 style="margin: 8px 0 0 0; color: #fff7ed; font-size: 30px; line-height: 1.12; font-weight: 950; border: 0;">Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4-GGUF-MTP</h1>
      </div>
      <div style="background: rgba(255,122,26,0.14); border: 1px solid rgba(255,122,26,0.72); color: #ffd7ad; font-size: 12px; font-weight: 900; padding: 8px 12px; border-radius: 999px;">RTX 5090 validated</div>
    </div>
    <p style="margin: 14px 0 0 0; max-width: 900px; color: #d6d3d1; font-size: 14px; line-height: 1.7;">
      A text-generation GGUF package for recent <code style="color:#ffb86b;">llama.cpp</code> builds: AEON Ultimate Uncensored NVFP4 trunk/body weights with a compatible MTP block, ready for Blackwell native FP4 local serving.
    </p>
  </div>

  <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(155px, 1fr)); gap: 1px; background: #2f2118;">
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Format</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">GGUF</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Quant</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">NVFP4</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Spec decode</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">draft-mtp</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Validated ctx</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">262k</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Target stack</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">llama.cpp</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Artifact</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">23.4 GB</b></div>
  </div>
</div>

> [!IMPORTANT]
> This repo publishes one recommended AEON-trunk MTP artifact. It was validated for text serving only; the original safetensors family is multimodal, but this GGUF card does not claim vision or multimodal serving support.

## Quick Start

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; margin: 18px 0 26px 0;">
  <div style="border:1px solid #3a2a1f; background:#111116; border-radius:14px; padding:16px;">
    <div style="color:#ffb86b; font-size:12px; font-weight:950; letter-spacing:0.8px; text-transform:uppercase;">Download</div>
    <p style="margin:8px 0 0 0; color:#e7e5e4; font-size:13px; line-height:1.65;">Use <code>ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf</code>. It is the AEON NVFP4 GGUF with grafted compatible MTP block.</p>
  </div>
  <div style="border:1px solid #3a2a1f; background:#111116; border-radius:14px; padding:16px;">
    <div style="color:#ffb86b; font-size:12px; font-weight:950; letter-spacing:0.8px; text-transform:uppercase;">Serve</div>
    <p style="margin:8px 0 0 0; color:#e7e5e4; font-size:13px; line-height:1.65;">Run with a current CUDA 13.x <code>llama.cpp</code> build and enable <code>--spec-type draft-mtp</code> or the tuned <code>draft-mtp,ngram-mod</code> profile.</p>
  </div>
  <div style="border:1px solid #3a2a1f; background:#111116; border-radius:14px; padding:16px;">
    <div style="color:#ffb86b; font-size:12px; font-weight:950; letter-spacing:0.8px; text-transform:uppercase;">Expect</div>
    <p style="margin:8px 0 0 0; color:#e7e5e4; font-size:13px; line-height:1.65;">On the tested RTX 5090 machine, <code>llama.cpp</code> initialized MTP at full 262k context and reported <code>BLACKWELL_NATIVE_FP4 = 1</code>.</p>
  </div>
</div>

## RTX 5090 Snapshot

RTX 5090, Windows, `llama.cpp-b9267-cuda13.1`, context `262144`, generation `1024` tokens, `temperature=0.6`.

| Runtime | Prompt | Decode tok/s | Full-wall tok/s | Prompt prefill |
| --- | ---: | ---: | ---: | ---: |
| Base native GGUF | 10k | 133.0 | 106.0 | 1.9s |
| AEON-trunk MTP GGUF | 10k | 131.5 | 101.5 | 2.2s |
| Base native GGUF | 200k | 82.1 | 18.9 | 41.0s |
| AEON-trunk MTP GGUF | 200k | 86.0 | 15.9 | 52.1s |

Tuning note: for the 10k prompt, `draft-mtp` with `--spec-draft-n-max 2` reached `133.7` decode tok/s and `104.0` full-wall tok/s. The chart uses the single temp=0.6 `draft-mtp,ngram-mod` profile for both prompt sizes.

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; border: 1px solid #3a2a1f; background: #0f0f13; border-radius: 16px; overflow: hidden; margin: 18px 0 28px 0;">
  <div style="padding: 14px 18px; background: linear-gradient(90deg, #1a120d 0%, #2b1708 100%); border-bottom: 1px solid rgba(255,122,26,0.35); color: #ffd7ad; font-weight: 950;">Windows native GGUF and MTP benchmark chart</div>
  <a href="https://huggingface.co/neko-legends/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4-GGUF-MTP/blob/main/images/aeon-ornith-windows-docker-vs-gguf.png" target="_blank" style="display:block; background:#050507;">
    <img src="https://huggingface.co/neko-legends/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4-GGUF-MTP/resolve/main/images/aeon-ornith-windows-docker-vs-gguf.png" alt="AEON Ornith Ultimate Uncensored NVFP4 Windows Docker vs native GGUF benchmark chart" style="display:block; width:100%; border:0;" />
  </a>
</div>

## Files

| File | Size | Notes |
| --- | ---: | --- |
| `ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf` | 23.4 GB (21.80 GiB) | Recommended AEON Ultimate Uncensored NVFP4 trunk/body GGUF with grafted compatible MTP block |
| `images/aeon-ornith-windows-docker-vs-gguf.png` | | RTX 5090 Windows benchmark comparison chart |

## Which File Should I Use?

Use `ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf` for the AEON Ultimate Uncensored NVFP4 GGUF with MTP serving support in `llama.cpp`. This repository intentionally publishes only the AEON-trunk MTP artifact.

This is a text-generation GGUF. The original safetensors model family is multimodal, but this GGUF file was validated for text serving only.

## MTP Provenance

AEON's compressed-tensors checkpoint advertises `mtp_num_hidden_layers = 1` in config metadata, but the downloaded `model.safetensors` contained no `mtp`, `nextn`, or `model.layers.40` tensor names. A direct conversion with MTP metadata failed in `llama.cpp` because `blk.40.attn_norm.weight` and the rest of the MTP block were absent.

The recommended MTP file in this repo was therefore built as a graft:

- Base/trunk/body: local base-only GGUF intermediate converted from [`AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4`](https://huggingface.co/AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4), not published in this repo
- MTP block donor: 20 `blk.40.*` tensors from [`s-batman/Ornith-1.0-35B-NVFP4-MTP-GGUF`](https://huggingface.co/s-batman/Ornith-1.0-35B-NVFP4-MTP-GGUF)
- Result metadata: `qwen35moe.block_count = 41`, `qwen35moe.nextn_predict_layers = 1`, `GGUF.tensor_count = 993`

Local validation confirmed `llama.cpp` initializes `draft-mtp` successfully at full 262k context and reports `BLACKWELL_NATIVE_FP4 = 1` on RTX 5090.

SHA256 for `ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf`:

```text
3F0545EE14ED3B01A18E794945E33FFE6876F9A3C3787316A652C6CFDE4BDDE3
```

## Example llama.cpp Command

```powershell
$LlamaServer = Join-Path "<path-to-llama.cpp-build-folder>" "llama-server.exe"
$Model = Join-Path "<path-to-model-folder>" "ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf"

& $LlamaServer `
  --model "$Model" `
  --alias aeon-ornith-1.0-35b-nvfp4-aeon-mtp `
  --host 127.0.0.1 `
  --port 39199 `
  --device CUDA0 `
  --gpu-layers all `
  --gpu-layers-draft all `
  --ctx-size 262144 `
  --cache-type-k q4_0 `
  --cache-type-v q4_0 `
  --cache-type-k-draft q4_0 `
  --cache-type-v-draft q4_0 `
  --flash-attn on `
  --parallel 1 `
  --cont-batching `
  --jinja `
  --metrics `
  --slots `
  --spec-type draft-mtp `
  --spec-draft-n-max 2 `
  --spec-draft-p-min 0.0
```

For very long prompts, `draft-mtp,ngram-mod` with `--spec-draft-n-max 3` was the better measured high-context profile in this run.

## RTX 5090 Windows Benchmark Details

| Runtime | Prompt target | Prompt tokens | Decode tok/s | Prompt prefill | Full-wall tok/s | Wall time |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Base native GGUF | 10k | 8,905 | 133.0 | 1.9s | 106.0 | 9.7s |
| AEON-trunk MTP GGUF | 10k | 8,905 | 131.5 | 2.2s | 101.5 | 10.1s |
| AEON-trunk MTP tuned n_max=2 | 10k | 8,905 | 133.7 | 2.1s | 104.0 | 9.8s |
| Base native GGUF | 200k | 174,588 | 82.1 | 41.0s | 18.9 | 54.1s |
| AEON-trunk MTP GGUF | 200k | 174,588 | 86.0 | 52.1s | 15.9 | 64.5s |

## Censorship Smoke Test

A short local smoke test against `ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf` on 2026-06-28 asked for neutral factual summaries of politically sensitive history/current-affairs topics. The model returned direct factual answers with no refusal or evasion markers detected. This is a small smoke test, not a formal safety or truthfulness evaluation.

## Source And Credits

- AEON NVFP4 source: [`AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4`](https://huggingface.co/AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4)
- MTP block donor: [`s-batman/Ornith-1.0-35B-NVFP4-MTP-GGUF`](https://huggingface.co/s-batman/Ornith-1.0-35B-NVFP4-MTP-GGUF)
- Base lineage: [`deepreinforce-ai/Ornith-1.0-35B`](https://huggingface.co/deepreinforce-ai/Ornith-1.0-35B)
- Local benchmark/launcher work: [`neko-legends/nvidia-local-llm-profiles`](https://github.com/neko-legends/nvidia-local-llm-profiles)

## Responsible Use

This is an uncensored/abliterated model family. You are responsible for downstream usage, deployment policy, and any application-level safeguards. Older `llama.cpp` builds may not load current GGUF/NVFP4 files correctly.
