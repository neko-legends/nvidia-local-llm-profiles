# AEON Ornith 1.0 35B Ultimate Uncensored NVFP4

Model: `AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4`

This is a compressed-tensors NVFP4 safetensors profile for vLLM on Blackwell
GPUs. It is not a GGUF/llama.cpp profile.

Runtime:

- Docker + vLLM
- Local endpoint: `http://127.0.0.1:39187/v1`
- Model id: `aeon-ornith-1.0-35b-nvfp4`
- Context profile: `262144`
- Quantization: `compressed-tensors`
- Mamba cache dtype: `float32`

Run:

```bat
download-aeon-ornith-1.0-35b-nvfp4.bat
start-aeon-ornith-1.0-35b-nvfp4-vllm-docker.bat
bench-aeon-ornith-1.0-35b-nvfp4-two-point.bat
```

Hermes:

```text
Provider: Local 5090
Model:    aeon-ornith-1.0-35b-nvfp4
```

The launcher follows the model card's stock vLLM settings: compressed-tensors
NVFP4, full 256k context, `--mamba-cache-dtype float32`, qwen3 reasoning parser,
prefix caching, and trusted remote code. The model card notes that NVFP4 requires
a Blackwell GPU.

On Windows Docker, serving from the default bind mount can make safetensors load
through Docker's 9P path. For faster startup, stage the downloaded snapshot into
the Docker volume `aeon-ornith-35b-nvfp4-model` and launch with
`MODEL_VOLUME=aeon-ornith-35b-nvfp4-model`.

Benchmark caveat: the first measured request after server startup can include
Triton kernel JIT latency. Use a warmed run for steady-state 10k decode numbers.
