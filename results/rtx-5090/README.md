# RTX 5090 Benchmark Results

- **GPU:** NVIDIA GeForce RTX 5090 32GB
- **Driver:** 610.62
- **Dates:** 2026-06-22 to 2026-06-23
- **Prompt style:** BookContext (synthetic long-document with continuity sections)
- **Generation:** 1024 tokens, temperature=0, seed=1234, 3 measured runs per context

![RTX 5090 long-context throughput comparison](../../assets/images/rtx-5090-context-ladder-comparison.svg)

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

### AEON Qwen3.6 27B Multimodal NVFP4 MTP-XS — vLLM — ctx=200k — fp8 KV — qwen3_5_mtp

| Context | Prompt tokens | avg tok/s | min | max | Power | Temp |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 8k | 7,303 | 47.8 | 46.8 | 48.8 | 162W | 47C |
| 33k | 28,663 | 44.7 | 39.1 | 48.8 | 170W | 50C |
| 66k | 57,284 | 41.0 | 35.3 | 44.0 | 176W | 53C |
| 131k | 114,465 | 38.8 | 23.7 | 46.5 | 187W | 57C |
| 200k | 174,588 | 35.5 | 18.6 | 44.7 | 216W | 59C |

- **Stack:** Docker `vllm/vllm-openai:latest` -> OpenAI-compatible endpoint at 127.0.0.1:39183
- **Model:** `AEON-7/Qwen3.6-27B-AEON-Ultimate-Uncensored-Multimodal-NVFP4-MTP-XS`
- **Flags:** `--quantization modelopt --kv-cache-dtype fp8 --max-model-len 200000 --max-num-seqs 1 --max-num-batched-tokens 8192 --gpu-memory-utilization 0.93 --speculative-config '{"method":"qwen3_5_mtp","num_speculative_tokens":3}'`

Notes on serving: the model loaded reliably from a Docker named volume on this
Windows host. The server reported a 200k max context and about 214k GPU KV-cache
tokens available.

---

## Key Findings

**Qwopus Q5 GGUF via llama.cpp stays interactive across the full 8k-256k ladder.**

- Short context peaks at **109.2 tok/s** @ 8k.
- Long context remains usable at **50.6 tok/s** @ 200k and **65.0 tok/s** @ 256k.
- The 256k run was benched separately with one warmup run, which explains the
  tighter spread there.

**AEON NVFP4 XS via vLLM fits the RTX 5090 and completed the 8k-200k ladder.**

- The tested vLLM profile used about 31.8GiB of the card's reported 32.6GiB
  during serving, mostly from model plus reserved KV-cache memory.
- Long-context generation stayed stable through the 200k target at
  **35.5 tok/s** average.
- Prompt prefill can briefly drive the core clock and power very high, which is
  why the Windows underclock profile matters even when VRAM is the real limiter.

---

## Thermal Note

The RTX 5090 reached 67C under sustained Qwopus load while drawing roughly
340-355W, and the AEON vLLM run briefly hit high prefill power during long
prompts before dropping back during generation. For future sweeps:

- Record ambient temperature and fan profile alongside the CSVs.
- Keep airflow stable before running long-context sessions.
- Re-run the 200k/256k contexts after any driver, llama.cpp, or launch-flag change.
