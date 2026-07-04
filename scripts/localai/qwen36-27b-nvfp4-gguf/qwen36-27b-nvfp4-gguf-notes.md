# NVIDIA Qwen3.6 27B NVFP4 MTP GGUF

Model: `nvidia/Qwen3.6-27B-NVFP4`

NVIDIA publishes this checkpoint as a ModelOpt/NVFP4 safetensors release with
vLLM as the supported runtime. The source snapshot includes an MTP block, and
this folder keeps it in the native GGUF/llama.cpp path.

Local source snapshot:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4
```

Local GGUF target:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4-MTP-GGUF\qwen3.6-27b-nvfp4-mtp-gguf.gguf
```

Artifact:

- Size: `28,230,538,624` bytes (`26.29 GiB`)
- SHA256: `5DECEF7638A9324664010695A49BA1C6EABD18FCFC1616B77C0AFF97B412A233`

Quick path:

```bat
download-qwen36-27b-nvfp4.bat

set LLAMA_CPP_SRC=C:\path\to\llama.cpp
convert-qwen36-27b-nvfp4-to-gguf.bat

set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
start-qwen36-27b-nvfp4-gguf-server.bat
```

Hermes:

```bat
install-hermes-qwen36-27b-nvfp4-gguf.bat
```

Default endpoint:

- Base URL: `http://127.0.0.1:39195/v1`
- Model: `qwen36-27b-nvfp4-mtp-gguf`
- Context: `--ctx-size 200000` on RTX 5090
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- MTP: `--spec-type draft-mtp --spec-draft-n-max 2`
- Thinking: disabled by default for the launcher and router path

Bench wrappers:

```bat
bench-qwen36-27b-nvfp4-gguf-no-mtp-two-point.bat
bench-qwen36-27b-nvfp4-gguf-two-point.bat
bench-qwen36-27b-nvfp4-gguf-mtp-vs-no-mtp-two-point.bat
```

RTX 5090 b9851 result at `ctx=200000`: MTP improved decode from `48.2` to
`67.9 tok/s` at the 10k prompt and from `32.9` to `41.3 tok/s` at the 200k
prompt. The MTP run used about `30.8 GiB`, so full 262k context is likely too
tight on a 32GB RTX 5090.

If conversion fails, update llama.cpp first. This model is newer than many
released converters and depends on support for Qwen3.6 and NVIDIA/ModelOpt
NVFP4 metadata.
