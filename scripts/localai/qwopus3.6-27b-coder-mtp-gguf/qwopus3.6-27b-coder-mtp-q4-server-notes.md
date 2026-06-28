# Qwopus3.6 27B Coder MTP Q4 local server

Model:

- Hugging Face repo: `Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF`
- File: `Qwopus3.6-27B-Coder-MTP-Q4_K_M.gguf`
- Runtime: llama.cpp CUDA (`llama-server.exe`)

Download the model:

```text
download-qwopus3.6-27B-Coder-MTP-Q4.bat
```

Default download location:

```text
<checkout-parent>\.local-model-cache\Jackrong\Qwopus3.6-27B-Coder-MTP-GGUF\
```

Start:

```text
start-qwopus3.6-27b-coder-mtp-q4-server.bat
```

Benchmark:

```text
bench-qwopus3.6-27b-coder-mtp-q4-two-point.bat
```

Endpoint:

- Base URL: `http://127.0.0.1:39186/v1`
- Model: `qwopus3.6-27b-coder-mtp-q4-k-m`

Current serving choices:

- Uses only the primary CUDA GPU: `--device CUDA0`
- Full GPU offload: `--gpu-layers all`
- Context: `--ctx-size 262144`
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- Flash attention: `--flash-attn on`
- One server slot: `--parallel 1`
- MTP + ngram speculative decoding: `--spec-type ngram-mod,draft-mtp --spec-draft-n-max 2`

This profile is intended as the lower-VRAM long-context fallback when the
Q5_K_M variant cannot fit the desired context on a single 32GB RTX 5090.

RTX 5090 quick benchmark. Full-request tok/s includes prompt read; generation
tok/s and prompt read come from llama.cpp `print_timing`.

| Context target | Prompt tokens | Full-request tok/s | Generation tok/s | Prompt read | Power | Temp |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 10k | 8,908 | 66.4 | 89.2 | 3.8s | 345W | 54C |
| 200k | 174,591 | 6.3 | 46.4 | 141.1s | 351W | 68C |
