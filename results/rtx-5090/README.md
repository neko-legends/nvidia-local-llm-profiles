# RTX 5090 Benchmark Results

**GPU:** NVIDIA GeForce RTX 5090 32GB  
**Driver:** 610.62  
**Date:** 2026-06-22  
**Prompt style:** BookContext (synthetic long-document with continuity sections)  
**Generation:** 1024 tokens, temperature=0, seed=1234, 3 measured runs per context

![RTX 5090 Qwopus context ladder bar chart](../../assets/images/rtx-5090-qwopus-context-ladder.svg)

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

## Key Findings

**Qwopus Q5 GGUF via llama.cpp stays interactive across the full 8k-256k ladder.**

- Short context peaks at **109.2 tok/s** @ 8k.
- Long context remains usable at **50.6 tok/s** @ 200k and **65.0 tok/s** @ 256k.
- The 256k run was benched separately with one warmup run, which explains the
  tighter spread there.

---

## Thermal Note

The RTX 5090 reached 67C under sustained Qwopus load while drawing roughly
340-355W. For future sweeps:

- Record ambient temperature and fan profile alongside the CSVs.
- Keep airflow stable before running long-context sessions.
- Re-run the 200k/256k contexts after any driver, llama.cpp, or launch-flag change.
