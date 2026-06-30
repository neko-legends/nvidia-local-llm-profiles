# NVIDIA Qwen3.6 35B A3B NVFP4 MTP GGUF

Model: `nvidia/Qwen3.6-35B-A3B-NVFP4`

Local GGUF target:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-35B-A3B-NVFP4-MTP-GGUF\qwen3.6-35b-a3b-nvfp4-mtp.gguf
```

The source snapshot already contains `mtp.*` tensors. The default conversion
keeps that MTP block bundled into the main GGUF so llama.cpp can use
`--spec-type draft-mtp`.

Quick path:

```bat
set LLAMA_CPP_SRC=C:\path\to\llama.cpp
convert-qwen36-35b-a3b-nvfp4-mtp-to-gguf.bat

set LLAMA_DIR=C:\path\to\llama.cpp-cuda-build
start-qwen36-35b-a3b-nvfp4-mtp-gguf-server.bat
bench-qwen36-35b-a3b-nvfp4-mtp-gguf-two-point.bat
```

Default endpoint:

- Base URL: `http://127.0.0.1:39194/v1`
- Model: `qwen36-35b-a3b-nvfp4-mtp-gguf`
- Context: `--ctx-size 200000`
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- MTP: `--spec-type draft-mtp --spec-draft-n-max 2`
- Thinking: disabled for the benchmark path
