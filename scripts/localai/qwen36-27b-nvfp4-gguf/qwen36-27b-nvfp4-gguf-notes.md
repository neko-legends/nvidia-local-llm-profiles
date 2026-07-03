# NVIDIA Qwen3.6 27B NVFP4 GGUF

Model: `nvidia/Qwen3.6-27B-NVFP4`

NVIDIA publishes this checkpoint as a ModelOpt/NVFP4 safetensors release with
vLLM as the supported runtime. This folder adds the repo's native GGUF/llama.cpp
scaffolding so the model can be tested through the same Windows Local 5090 path
as the other profiles.

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
- Model: `qwen36-27b-nvfp4-gguf`
- Context: `--ctx-size 262144`
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- Thinking: disabled by default for the launcher and router path

If conversion fails, update llama.cpp first. This model is newer than many
released converters and depends on support for Qwen3.6 and NVIDIA/ModelOpt
NVFP4 metadata.
