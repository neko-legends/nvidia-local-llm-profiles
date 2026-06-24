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
| 200k | 174,590 | 14.2 | 222W | 57C |
