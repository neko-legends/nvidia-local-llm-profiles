# AEON Qwen3.6 27B Multimodal NVFP4 MTP-XS vLLM Server

Model:

- Hugging Face repo: `AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP-XS`
- License: Apache-2.0
- Format: safetensors, modelopt NVFP4, MTP head
- Runtime: vLLM through `vllm/vllm-openai:latest`

This is not a GGUF model. Use the Docker/vLLM launcher in this folder rather
than the llama.cpp launcher used by the Qwopus profile.

Download the model:

```text
download-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs.bat
```

Start the server:

```text
start-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-docker.bat
```

Benchmark with the same context ladder used for Qwopus:

```text
bench-aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-context-ladder.bat
```

Hermes settings:

- Provider type/API: OpenAI-compatible chat completions
- Desktop base URL: `http://127.0.0.1:39183/v1`
- LAN base URL: `http://<your-server-lan-ip>:39183/v1`
- API key: empty, `none`, or any placeholder if Hermes requires one
- Model: `aeon-qwen36-27b-multimodal-nvfp4-mtp-xs`

Serving choices:

- Dedicated-VRAM Blackwell route: vLLM with `--quantization modelopt`
- Context: `--max-model-len 200000`
- KV cache: `--kv-cache-dtype fp8`
- Concurrency: `--max-num-seqs 1`
- Speculative decoding: `--speculative-config '{"method":"qwen3_5_mtp","num_speculative_tokens":3}'`
- GPU memory cap: `--gpu-memory-utilization 0.93`
- Multimodal prompt cap: `--limit-mm-per-prompt '{"image":4,"video":2}'`

On this Windows test box, serving from a Docker named volume loaded reliably
while a direct Windows bind mount was slow or stuck during safetensors loading.
The launcher copies the downloaded snapshot into `aeon-qwen36-mtp-xs-model`
the first time it starts.

If startup fails with out-of-memory, lower `GPU_MEMORY_UTILIZATION` or
`MAX_MODEL_LEN` in the launcher and record the changed values with any benchmark
results.
