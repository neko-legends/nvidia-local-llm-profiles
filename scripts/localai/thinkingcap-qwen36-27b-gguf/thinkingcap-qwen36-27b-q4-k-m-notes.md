# ThinkingCap Qwen3.6 27B Q4_K_M

The upstream `ThinkingCap-Qwen3.6-27B-Q4_K_M.gguf` already contains its MTP draft head. Use a recent CUDA llama.cpp build and `--spec-type draft-mtp`; no conversion or external draft GGUF is required.

The launcher defaults to 200k context, q4_0 target/draft KV caches, MTP `n=4`, and no-thinking. Set `THINKING=1` to enable reasoning output or `SPEC_DRAFT_N_MAX` to tune the MTP draft length.
