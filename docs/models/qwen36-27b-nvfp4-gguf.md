# NVIDIA Qwen3.6 27B NVFP4 GGUF

Native GGUF conversion scaffolding for
[`nvidia/Qwen3.6-27B-NVFP4`](https://huggingface.co/nvidia/Qwen3.6-27B-NVFP4).
NVIDIA publishes the source checkpoint as a ModelOpt/NVFP4 safetensors release
with vLLM as the supported runtime. This repo adds the native Windows
GGUF/llama.cpp path so it can be tested through the same Local 5090 workflow as
the other models.

Local source snapshot:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4
```

Local GGUF target:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4-GGUF\qwen3.6-27b-nvfp4.gguf
```

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
- Context: `262144`
- KV cache: `q4_0` target K/V
- Thinking: disabled by default in the launcher and Local 5090 router path

If conversion fails, update llama.cpp first. This model is newer than many
released converters and depends on support for Qwen3.6 plus NVIDIA/ModelOpt
NVFP4 metadata.
