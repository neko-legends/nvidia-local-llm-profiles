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

![RTX 5090 native llama.cpp long-context comparison](rtx-5090-qwen35-moe-vs-qwopus.png)

# Qwen3.6 35B A3B NVFP4 MTP GGUF

Native GGUF conversion of
[`nvidia/Qwen3.6-35B-A3B-NVFP4`](https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4)
for recent llama.cpp builds on Windows/Linux. The GGUF keeps NVIDIA's native
NVFP4 body and the bundled MTP block from the source snapshot.

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
