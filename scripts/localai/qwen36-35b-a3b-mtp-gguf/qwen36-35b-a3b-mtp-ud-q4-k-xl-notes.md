# Unsloth Qwen3.6 35B A3B MTP GGUF

Model: `unsloth/Qwen3.6-35B-A3B-MTP-GGUF`

File:

- `Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf`

Runtime:

- llama.cpp CUDA
- MTP: `--spec-type draft-mtp --spec-draft-n-max 2`
- Local endpoint: `http://127.0.0.1:39185/v1`
- Model id: `qwen36-35b-a3b-mtp-ud-q4-k-xl`

Run:

```bat
download-qwen36-35b-a3b-ud-q4-k-xl.bat
start-qwen36-35b-a3b-mtp-ud-q4-k-xl-server.bat
bench-qwen36-35b-a3b-mtp-ud-q4-k-xl-two-point.bat
```

The Unsloth model card recommends llama.cpp with flash attention and MTP
speculative decoding for this GGUF family.

RTX 5090 quick benchmark:

| Context target | Prompt tokens | tok/s | Power | Temp |
| ---: | ---: | ---: | ---: | ---: |
| 10k | 8,907 | 96.3 | 174W | 46C |
| 200k | 174,590 | 14.8 | 226W | 57C |

Token accounting: the benchmark sends the generated BookContext prompt inline as
the user message. The reported tok/s is completion tokens divided by full
request wall time, including prompt ingestion and prefill. Dragging the prompt
file into a UI can invoke attachment/RAG behavior, so it may not test the same
number of prompt tokens.

The headless check was run after moving display output to the RTX 3090. It did
not materially improve throughput: 95.8 tok/s at 10k and 14.7 tok/s at 200k.
