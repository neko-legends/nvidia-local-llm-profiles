# Unsloth Qwen3.6 35B A3B NVFP4 MTP GGUF

This profile converts `unsloth/Qwen3.6-35B-A3B-NVFP4` to a native llama.cpp
GGUF and retains the source checkpoint's bundled MTP block. The default
launcher uses 200k context, q4_0 KV caches, Flash Attention, `draft-mtp` n=2,
and thinking disabled for Hermes coding use.

Run `download-qwen36-35b-a3b-unsloth-nvfp4.bat`, set `LLAMA_CPP_SRC`, then run
the converter. Set `LLAMA_DIR` to a recent CUDA llama.cpp build before starting.

## Fast variant

`unsloth/Qwen3.6-35B-A3B-NVFP4-Fast` retains more expert layers as native
NVFP4. Run the Fast download, conversion, b10068 runtime installer, Hermes
installer, and start scripts in that order. The output filename is
`qwen3.6-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.gguf`.

The tested preset uses llama.cpp b10068, 200k context, q4_0 target/draft KV,
no-thinking, and `draft-mtp n=2`. Source and output caches stay outside Git.

Measured on Windows 11 with one RTX 5090 and the shared BookContext fixtures:

| Prompt | Prompt tokens | Decode | Prefill | MTP acceptance | VRAM after |
| --- | ---: | ---: | ---: | ---: | ---: |
| 10k | 8,907 | 135.23 tok/s | 2.16s | 60.7% | 25,138 MiB |
| 200k | 174,590 | 84.08 tok/s | 52.84s | 59.7% | 25,138 MiB |

The Fast conversion is 22,905,198,464 bytes. It is smaller than the earlier
mixed NVFP4/FP8 conversion, but its vLLM-focused Fast advantage did not carry
over to this single-request native llama.cpp benchmark.
