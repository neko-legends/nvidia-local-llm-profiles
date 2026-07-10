# Unsloth Qwen3.6 27B NVFP4 MTP GGUF

This profile converts `unsloth/Qwen3.6-27B-NVFP4` to a native llama.cpp GGUF
and retains the source checkpoint's bundled MTP block. The default launcher
uses 200k context, q4_0 KV caches, Flash Attention, `draft-mtp` n=2, and
thinking disabled for Hermes coding use.

Run `download-qwen36-27b-unsloth-nvfp4.bat`, set `LLAMA_CPP_SRC`, then run the
converter. Set `LLAMA_DIR` to a recent CUDA llama.cpp build before starting.
