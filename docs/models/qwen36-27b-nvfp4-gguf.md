# NVIDIA Qwen3.6 27B NVFP4 MTP GGUF

Native GGUF conversion scaffolding for
[`nvidia/Qwen3.6-27B-NVFP4`](https://huggingface.co/nvidia/Qwen3.6-27B-NVFP4).
NVIDIA publishes the source checkpoint as a ModelOpt/NVFP4 safetensors release
with vLLM as the supported runtime. The source snapshot includes an MTP block,
and this repo keeps it in the native Windows GGUF/llama.cpp path so it can be
tested through the same Local 5090 workflow as the other models.

Local source snapshot:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4
```

Local GGUF target:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4-GGUF\qwen3.6-27b-nvfp4-mtp.gguf
```

Local artifact:

- Size: `28,230,538,624` bytes (`26.29 GiB`)
- SHA256: `5DECEF7638A9324664010695A49BA1C6EABD18FCFC1616B77C0AFF97B412A233`
- Source metadata: `mtp_num_hidden_layers=1`
- Source tensor map includes `mtp.layers.0.*`

Quick path:

```bat
scripts\localai\qwen36-27b-nvfp4-gguf\download-qwen36-27b-nvfp4.bat
set LLAMA_CPP_SRC=C:\path\to\llama.cpp
scripts\localai\qwen36-27b-nvfp4-gguf\convert-qwen36-27b-nvfp4-to-gguf.bat
set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
scripts\localai\qwen36-27b-nvfp4-gguf\start-qwen36-27b-nvfp4-gguf-server.bat
```

Hermes:

```bat
scripts\localai\qwen36-27b-nvfp4-gguf\install-hermes-qwen36-27b-nvfp4-gguf.bat
```

Default endpoint:

- Base URL: `http://127.0.0.1:39195/v1`
- Model: `qwen36-27b-nvfp4-gguf`
- Context: `200000` on RTX 5090
- KV cache: `q4_0` target K/V and draft K/V
- Speculative decoding: `draft-mtp`, `--spec-draft-n-max 2`
- Thinking: disabled by default in the launcher and Local 5090 router path

RTX 5090 b9851 no-MTP vs MTP result:

| Context | No MTP decode tok/s | MTP decode tok/s | Change | Prompt prefill | MTP acceptance |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10k | 48.2 | 67.9 | +40.7% | 3.1s | 66.9% |
| 200k | 32.9 | 41.3 | +25.6% | 131.8s | 68.3% |

The 200k MTP run used about `30.8 GiB` after request on the RTX 5090. That is
why this repo advertises the local 5090 route at `200000` context instead of the
model card's maximum 262k context.

If conversion fails, update llama.cpp first. This model is newer than many
released converters and depends on support for Qwen3.6 plus NVIDIA/ModelOpt
NVFP4 metadata.
