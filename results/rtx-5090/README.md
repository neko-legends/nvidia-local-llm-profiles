# RTX 5090 Benchmark Results

**GPU:** NVIDIA GeForce RTX 5090 32GB  
**Driver:** 610.62  
**Date:** 2026-06-22  
**Prompt style:** BookContext (synthetic long-document with continuity sections)  
**Generation:** 1024 tokens, temperature=0, seed=1234, 1 warmup + 3 measured runs

---

## Results

### Qwopus3.6-27B-Coder-MTP-Q5_K_M — llama.cpp b9761 — ctx=256k — MTP n=2

| Context | Prompt tokens | avg tok/s | min | max | Power | Temp |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 8k | 7,303 | 109.2 | 99.8 | 116.6 | 355W | 54C |
| 33k | 28,663 | 82.0 | 52.1 | 97.7 | 351W | 58C |
| 66k | 57,284 | 90.8 | 35.1 | 127.5 | 354W | 63C |
| 131k | 114,465 | 63.2 | 16.5 | 94.6 | 341W | 65C |
| 200k | 174,588 | 50.6 | 11.4 | 72.4 | 340W | 67C |
| 256k | 228,835 | 65.0 | 56.5 | 73.0 | 340W | 64C |

**Stack:** LocalAI launcher → llama.cpp server → OpenAI-compatible endpoint at 127.0.0.1:39182  
**Model:** `Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf`  
**Flags:** `-ngl 999 -fa on -c 262144 -np 1 --spec-type draft-mtp --spec-draft-n-max 2 --spec-draft-ngl 999`

Notes on variance: the wide min/max at 33k–131k is MTP draft hit/miss variance
on cold KV cache. Run 1 includes prefill overhead; runs 2–3 are decode-only and
are tighter. The 256k run was benched separately with a warmup run which explains
the tighter spread.

---

### Qwen3.6-27B-Text-NVFP4-MTP — vLLM 0.23 Docker — ctx=200k — MTP n=2

| Context | Prompt tokens | avg tok/s | min | max | Power | Temp |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 200k | 174,588 | 12.6 | 12.5 | 12.6 | 209W | 64C |

**Stack:** Docker (vllm/vllm-openai:latest) → OpenAI-compatible endpoint at 127.0.0.1:8892  
**Model:** `Qwen3.6-27B-Text-NVFP4-MTP` safetensors (ModelOpt FP4 quantization)  
**Flags:** `--quantization modelopt --language-model-only --max-model-len 200000 --gpu-memory-utilization 0.93 --kv-cache-dtype fp8 --speculative-config {"method":"qwen3_5_mtp","num_speculative_tokens":2}`  
**Kernel:** FlashInferCutlassNvFp4LinearKernel (Blackwell FP4 GEMM)

MTP n sweep (n=1,3,4,5) was aborted after system crash from thermal load during
the 20-minute vLLM startup cycle. Only n=2 result is confirmed.

---

## Key Findings

**Qwopus Q5 GGUF via llama.cpp is 4x faster than Qwen NVFP4 via vLLM at 200k context.**

- Qwopus: **50.6 tok/s** @ 200k, **109 tok/s** @ 8k, runs at 340–355W
- Qwen NVFP4: **12.6 tok/s** @ 200k (only context tested), runs at 209W

The NVFP4 path uses less power but produces ~4x lower throughput at long context.
Likely causes:
1. 200k context = ~6-8 GB fp8 KV cache + 19 GB model = tight against 32 GB ceiling, memory bandwidth dominated
2. vLLM + Docker + 9P VirtioFS bind mount adds overhead llama.cpp avoids
3. MTP n=2 may not be optimal for this model/context combination

**The MTP sweep is incomplete.** n=1 (no draft overhead) at a shorter context
(e.g. 8k–32k) would likely show a very different result for the NVFP4 path since
FP4 tensor cores should dominate at short context where KV cache is not the bottleneck.

---

## Thermal Note

The RTX 5090 reached 67C under sustained Qwopus load (340W). The vLLM startup
cycle (20 min of weight loading + torch.compile + CUDA graph capture, repeated
per MTP value) caused a system crash from thermal overload. For future sweeps:
- Ensure adequate case airflow before running vLLM startup cycles
- Consider `--safetensors-load-strategy=prefetch` to speed up the 9P VirtioFS load
- Cap sweep to 2–3 MTP values max per session
