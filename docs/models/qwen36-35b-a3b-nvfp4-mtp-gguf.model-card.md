---
license: apache-2.0
base_model:
- Qwen/Qwen3.6-35B-A3B
library_name: llama.cpp
tags:
- gguf
- nvfp4
- mtp
- qwen3.6
- qwen35moe
- blackwell
- rtx-5090
---

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; border: 1px solid #3a2a1f; background: #0f0f13; border-radius: 16px; overflow: hidden; margin: 0 0 28px 0; box-shadow: 0 20px 48px rgba(0,0,0,0.24);">
  <div style="padding: 14px 18px; background: linear-gradient(90deg, #1a120d 0%, #2b1708 100%); border-bottom: 1px solid rgba(255,122,26,0.35); color: #ffd7ad; font-weight: 950;">RTX 5090 native llama.cpp benchmark chart</div>
  <a href="./rtx-5090-qwen35-moe-vs-qwopus.png" target="_blank" style="display:block; background:#050507;">
    <img src="./rtx-5090-qwen35-moe-vs-qwopus.png" alt="RTX 5090 native llama.cpp long-context comparison" style="display:block; width:100%; border:0;" />
  </a>
</div>

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; border: 1px solid #2f2118; border-radius: 18px; overflow: hidden; background: #0b0b0f; box-shadow: 0 20px 48px rgba(0,0,0,0.26); margin: 0 0 28px 0;">
  <div style="padding: 30px 28px 24px 28px; background: radial-gradient(circle at 8% 0%, rgba(255,122,26,0.34), transparent 34%), radial-gradient(circle at 92% 10%, rgba(255,184,107,0.18), transparent 26%), linear-gradient(135deg, #050507 0%, #111116 54%, #1f1209 100%); border-bottom: 1px solid rgba(255,122,26,0.35);">
    <div style="display: flex; flex-wrap: wrap; gap: 14px; align-items: center; justify-content: space-between;">
      <div>
        <div style="font-size: 11px; font-weight: 900; color: #ffb86b; letter-spacing: 1.8px; text-transform: uppercase;">Neko Legends local inference release</div>
        <h1 style="margin: 8px 0 0 0; color: #fff7ed; font-size: 30px; line-height: 1.12; font-weight: 950; border: 0;">Qwen3.6-35B-A3B-NVFP4-MTP-GGUF</h1>
      </div>
      <div style="background: rgba(255,122,26,0.14); border: 1px solid rgba(255,122,26,0.72); color: #ffd7ad; font-size: 12px; font-weight: 900; padding: 8px 12px; border-radius: 999px;">RTX 5090 validated</div>
    </div>
    <p style="margin: 14px 0 0 0; max-width: 900px; color: #d6d3d1; font-size: 14px; line-height: 1.7;">
      A native <code style="color:#ffb86b;">llama.cpp</code> GGUF conversion of NVIDIA's Qwen3.6 35B A3B NVFP4 release, preserving the compact NVFP4 body and bundled MTP block for Blackwell native FP4 serving.
    </p>
  </div>

  <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(155px, 1fr)); gap: 1px; background: #2f2118;">
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Format</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">GGUF</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Quant</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">NVFP4</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Spec decode</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">draft-mtp</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Model ctx</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">262k</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Bench ctx</span><b style="display:block; margin-top:5px; color:#fff7ed; font-size:18px;">200k</b></div>
    <div style="background:#111116; padding: 15px 16px;"><span style="display:block; color:#a8a29e; font-size:11px; font-weight:900; text-transform:uppercase;">Artifact</span><b style="display:block; margin-top:5px; color:#ffb86b; font-size:18px;">23.9 GB</b></div>
  </div>
</div>

# Qwen3.6 35B A3B NVFP4 MTP GGUF

Native GGUF conversion of
[`nvidia/Qwen3.6-35B-A3B-NVFP4`](https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4)
for recent llama.cpp builds on Windows/Linux. The GGUF keeps NVIDIA's native
NVFP4 body and the bundled MTP block from the source snapshot.

## Quick Start

<div style="font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 14px; margin: 18px 0 26px 0;">
  <div style="border:1px solid #3a2a1f; background:#111116; border-radius:14px; padding:16px;">
    <div style="color:#ffb86b; font-size:12px; font-weight:950; letter-spacing:0.8px; text-transform:uppercase;">Download</div>
    <p style="margin:8px 0 0 0; color:#e7e5e4; font-size:13px; line-height:1.65;">Use <code>qwen3.6-35b-a3b-nvfp4-mtp.gguf</code>. It is the native NVFP4 GGUF with NVIDIA's bundled MTP block preserved.</p>
  </div>
  <div style="border:1px solid #3a2a1f; background:#111116; border-radius:14px; padding:16px;">
    <div style="color:#ffb86b; font-size:12px; font-weight:950; letter-spacing:0.8px; text-transform:uppercase;">Serve</div>
    <p style="margin:8px 0 0 0; color:#e7e5e4; font-size:13px; line-height:1.65;">Run with a recent CUDA <code>llama.cpp</code> build and enable <code>--spec-type draft-mtp</code> with <code>--spec-draft-n-max 2</code>.</p>
  </div>
  <div style="border:1px solid #3a2a1f; background:#111116; border-radius:14px; padding:16px;">
    <div style="color:#ffb86b; font-size:12px; font-weight:950; letter-spacing:0.8px; text-transform:uppercase;">Expect</div>
    <p style="margin:8px 0 0 0; color:#e7e5e4; font-size:13px; line-height:1.65;">On RTX 5090, <code>llama.cpp</code> reported <code>BLACKWELL_NATIVE_FP4 = 1</code> and initialized the bundled MTP context.</p>
  </div>
  <div style="border:1px solid #3a2a1f; background:#111116; border-radius:14px; padding:16px;">
    <div style="color:#ffb86b; font-size:12px; font-weight:950; letter-spacing:0.8px; text-transform:uppercase;">Benchmark</div>
    <p style="margin:8px 0 0 0; color:#e7e5e4; font-size:13px; line-height:1.65;">Use the included <code>benchmark-prompts/book-context-10k.txt</code> and <code>benchmark-prompts/book-context-200k.txt</code> fixtures to reproduce the chart rows.</p>
  </div>
</div>

## File

| File | Size | SHA256 |
| --- | ---: | --- |
| `qwen3.6-35b-a3b-nvfp4-mtp.gguf` | 23,850,227,712 bytes / 22.21 GiB | `B7C0806BD45428DA1A980A1A8F68279FD85D7D56292D64AAD97C65CB5FDD8C91` |

Verified GGUF metadata:

- `general.architecture = qwen35moe`
- `general.file_type = 39`
- `qwen35moe.context_length = 262144`
- `qwen35moe.nextn_predict_layers = 1`

## RTX 5090 Benchmark

Same BookContext prompt fixtures, 1024 generated tokens, temperature 0, seed
1234, llama.cpp b9761, NVIDIA driver 610.62. The chart and `Generation tok/s`
use llama.cpp decode-only timing; `Full request tok/s` includes prompt prefill.

| Context | Prompt tokens | Full request tok/s | Generation tok/s | Prompt read | MTP acceptance |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10k | 8,907 | 105.0 | 146.8 | 2.6s | 67.6% |
| 200k | 174,590 | 16.0 | 88.5 | 51.8s | 60.2% |

Benchmark prompt files are included in this repo:

| File | SHA256 | Notes |
| --- | --- | --- |
| [`benchmark-prompts/book-context-10k.txt`](./benchmark-prompts/book-context-10k.txt) | `785c5b31d1ce77612431b1289c0a097ed51ab1a6d4a07bccfb7a70f59df55f94` | 42,940 bytes; tokenized as 8,907 prompt tokens in this run |
| [`benchmark-prompts/book-context-200k.txt`](./benchmark-prompts/book-context-200k.txt) | `a794ca243983eb3387bec6728db4b0c72a99ee2a98cfee7223269708e4ae228c` | 840,403 bytes; tokenized as 174,590 prompt tokens in this run |

Serving flags used for the benchmark:

```bash
llama-server \
  --model qwen3.6-35b-a3b-nvfp4-mtp.gguf \
  --alias qwen36-35b-a3b-nvfp4-mtp-gguf \
  --host 0.0.0.0 \
  --port 39194 \
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

The server reported `BLACKWELL_NATIVE_FP4=1`, initialized `draft-mtp` with
`n_max=2`, and logged `chat template, thinking = 0`.

## Conversion

The conversion was done with a recent llama.cpp `convert_hf_to_gguf.py`.

```bash
python convert_hf_to_gguf.py \
  /path/to/Qwen3.6-35B-A3B-NVFP4 \
  --outfile qwen3.6-35b-a3b-nvfp4-mtp.gguf \
  --outtype auto \
  --model-name nvidia-Qwen3.6-35B-A3B-NVFP4-MTP
```

No `--no-mtp` flag was used. The source snapshot already includes `mtp.*`
tensors, and the exported GGUF has `qwen35moe.nextn_predict_layers = 1`.

## Notes

- Best target hardware is Blackwell-class NVIDIA GPUs with a llama.cpp build
  that reports native FP4 support.
- The benchmark used request-level no-thinking mode via
  `chat_template_kwargs.enable_thinking=false`.
- License is Apache 2.0, inherited from the NVIDIA/Qwen source release.
