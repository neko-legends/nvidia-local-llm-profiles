# AEON Qwen3.6 27B Multimodal NVFP4 MTP-XS

Model:

- Hugging Face repo: `AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP-XS`
- License: Apache-2.0
- Format: safetensors, modelopt NVFP4, multimodal, MTP head
- Runtime: vLLM OpenAI server container
- Local launcher folder: `scripts\vllm\aeon-qwen36-27b-multimodal-nvfp4-mtp-xs\`

Why this profile exists:

- It is the RTX 5090-class AEON XS variant: the model card positions it for
  24-32GB dedicated-VRAM cards where the smaller NVFP4 footprint buys KV-cache
  headroom.
- It preserves the multimodal vision tower and uses the grafted MTP head for
  dedicated-VRAM Blackwell speculative decoding.
- It exposes the same OpenAI-compatible endpoint shape as the Qwopus profile, so
  the existing benchmark scripts can compare context-ladder behavior.

Download:

```text
scripts\vllm\aeon-qwen36-27b-multimodal-nvfp4-mtp-xs\download-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.bat
```

Start:

```text
scripts\vllm\aeon-qwen36-27b-multimodal-nvfp4-mtp-xs\start-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-docker.bat
```

Benchmark:

```text
scripts\vllm\aeon-qwen36-27b-multimodal-nvfp4-mtp-xs\bench-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-context-ladder.bat
```

Endpoint:

- Base URL: `http://127.0.0.1:39183/v1`
- Model: `aeon-qwen36-27b-multimodal-nvfp4-mtp-xs`

Notes:

- This is not a llama.cpp/GGUF profile.
- The tested RTX 5090 Windows profile uses `vllm/vllm-openai:latest`,
  `--quantization modelopt`, `--kv-cache-dtype fp8`, `--max-model-len 200000`,
  `--max-num-seqs 1`, and `qwen3_5_mtp` speculative decoding with
  `num_speculative_tokens=3`.
- The launcher copies the downloaded snapshot into a Docker named volume before
  serving. This avoids slow or stuck safetensors loading through a Windows bind
  mount.
- Keep the RTX 5090 underclock/stability profile in place before long runs.

RTX 5090 benchmark summary:

| Context target | Prompt tokens | Avg tok/s | Min | Max | Power | Temp |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 8k | 7,303 | 47.8 | 46.8 | 48.8 | 162W | 47C |
| 33k | 28,663 | 44.7 | 39.1 | 48.8 | 170W | 50C |
| 66k | 57,284 | 41.0 | 35.3 | 44.0 | 176W | 53C |
| 131k | 114,465 | 38.8 | 23.7 | 46.5 | 187W | 57C |
| 200k | 174,588 | 35.5 | 18.6 | 44.7 | 216W | 59C |
