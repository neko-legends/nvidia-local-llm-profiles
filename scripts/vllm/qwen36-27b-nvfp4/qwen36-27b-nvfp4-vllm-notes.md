# NVIDIA Qwen3.6 27B NVFP4 vLLM

Docker/vLLM launcher for the official ModelOpt NVFP4 safetensors checkpoint.
vLLM is the recommended path for NVIDIA ModelOpt NVFP4 safetensors, but this
profile is explicitly a Windows 11 + Docker Desktop compatibility setup. For
best NVFP4 performance, expect native Linux vLLM-class serving to be the better
target.

- Source: `nvidia/Qwen3.6-27B-NVFP4`
- Local source snapshot: `<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-27B-NVFP4`
- Runtime: Windows 11 host, Docker Desktop, `vllm/vllm-openai:nightly`
- Endpoint: `http://127.0.0.1:39196/v1`
- Model alias: `qwen36-27b-nvfp4-vllm`
- Default context: `200000`
- KV cache: `fp8`
- Speculative decoding: disabled for the baseline launcher
- FlashInfer blockscale FP8 GEMM and max autotune are disabled by default to
  avoid very long startup/autotune on this Windows 11 Docker/RTX 5090 profile.

Run:

```bat
scripts\vllm\qwen36-27b-nvfp4\start-qwen36-27b-nvfp4-vllm-docker.bat
```

Then benchmark with the shared BookContext 10k and 200k prompt fixtures:

```bat
scripts\vllm\qwen36-27b-nvfp4\bench-qwen36-27b-nvfp4-vllm-two-point.bat
```

The benchmark case name includes `vllm-docker` so results are not confused with
native Windows GGUF/llama.cpp numbers.

MTP/speculative decoding is intentionally not enabled in the baseline script.
It uses extra memory, and 200k context is already close to the practical limit
on a 32GB RTX 5090 depending on desktop GPU load.

## RTX 5090 Windows 11 Docker Baseline

Two-point smoke benchmark, one measured run per context, same BookContext prompt
fixtures as the native GGUF tests.

| Context target | Prompt tokens | Full-request tok/s | Engine decode tok/s | Notes |
| ---: | ---: | ---: | ---: | --- |
| 10k cold request | 8,907 | 28.5 | ~34.8 after JIT | First request compiled several Triton kernels during inference |
| 10k warmed rerun | 8,907 | 32.1 | ~34.8 | Same loaded server, no MTP |
| 200k | 174,590 | 9.24 | ~30.9 | Long prompt dominates wall time |

Runtime details from the successful run:

- Host: Windows 11, Docker Desktop, RTX 5090 32GB, driver 610.62
- Docker image: `vllm/vllm-openai:nightly`
- vLLM version: `0.23.1rc1.dev301+g04c2a8dea`
- Context: `--max-model-len 200000`
- GPU KV cache capacity reported by vLLM: `223,880` tokens
- Maximum concurrency at 200k: `1.12x`
- Idle/served memory after startup: about `28.0 GiB`
- Memory after benchmark requests: about `30.6 GiB`
- Startup took roughly 8 minutes to ready the endpoint with this profile.

The first attempt with default FlashInfer autotune kept tuning for over 13
minutes, so the checked-in launcher disables that path with
`--no-enable-flashinfer-autotune`,
`VLLM_BLOCKSCALE_FP8_GEMM_FLASHINFER=0`, and
`VLLM_ENABLE_INDUCTOR_MAX_AUTOTUNE=0`.

Important warning observed in the vLLM log:

```text
Your GPU does not have native support for FP4 computation but FP4 quantization is being used. Weight-only FP4 compression will be used leveraging the Marlin kernel.
```

That means this Windows 11 Docker/vLLM/RTX 5090 result should not be read as
the same class of run as native Linux vLLM or RTX PRO 6000 Blackwell screenshots
reporting hundreds of tok/s.
