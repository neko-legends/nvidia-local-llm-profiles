# NVIDIA Qwen3.6 35B A3B NVFP4 MTP GGUF

Native GGUF conversion of `nvidia/Qwen3.6-35B-A3B-NVFP4`, saved for upload to
`neko-legends/Qwen3.6-35B-A3B-NVFP4-MTP-GGUF`.

Local GGUF:

```text
<checkout-parent>\.local-model-cache\nvidia\Qwen3.6-35B-A3B-NVFP4-MTP-GGUF\qwen3.6-35b-a3b-nvfp4-mtp.gguf
```

Artifact verification:

- Size: `23,850,227,712` bytes (`22.21 GiB`)
- SHA256: `B7C0806BD45428DA1A980A1A8F68279FD85D7D56292D64AAD97C65CB5FDD8C91`
- GGUF: `qwen35moe`, `file_type=39`, `context_length=262144`
- MTP: `nextn_predict_layers=1`

The source snapshot already contains `mtp.*` tensors. The conversion keeps the
MTP block bundled in the main GGUF, so llama.cpp can use `--spec-type draft-mtp`
without a grafted or separate draft model.

Benchmark command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File `
  .\scripts\localai\qwen36-35b-a3b-nvfp4-mtp-gguf\bench-with-server-qwen36-35b-a3b-nvfp4-mtp-gguf.ps1 `
  -LlamaDir C:\path\to\llama.cpp-cuda-build `
  -ContextSize 200000 `
  -SpecType draft-mtp `
  -SpecDraftNMax 2
```

RTX 5090 b9761 results:

| Context | Prompt tokens | Full-request tok/s | Decode tok/s | Prompt read | MTP acceptance |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10k | 8,907 | 105.0 | 146.8 | 2.6s | 67.6% |
| 200k | 174,590 | 16.0 | 88.5 | 51.8s | 60.2% |

The server log reported `BLACKWELL_NATIVE_FP4=1` and initialized
`draft-mtp` with `n_max=2`. The benchmark sent no-thinking requests and the
server logged `chat template, thinking = 0`.
