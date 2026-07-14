# Ternary-Bonsai 27B with DSpark Q4_1

This native Windows CUDA profile uses PrismML's quality-oriented `Q2_0_g128` target and its recommended Q4_1 DSpark speculative drafter. The drafter proposes four-token blocks; target verification preserves the target distribution.

Run, in order:

```bat
build-prism-llamacpp-sm120-runtime.bat
download-ternary-bonsai-27b-dspark-q4-1.bat
install-hermes-ternary-bonsai-27b-dspark-q4-1.bat
start-ternary-bonsai-27b-dspark-q4-1-server.bat
```

The RTX 5090 build script compiles PrismML commit `62061f9` for CUDA architecture `120a`; PrismML's CUDA 12.4 prebuilt lacks native Blackwell kernels and is much slower. The DSpark launcher defaults to its officially supported 16,384-token server context, q4_0 target/draft KV caches, no reasoning output, port 39199, and `draft-dspark n=4`. Use `start-ternary-bonsai-27b-full-context-no-dspark-server.bat` for the target's full 262,144-token context. PrismML's current DSpark server path stages the entire context in one batch, so DSpark is not practical at 200K on a 32 GB GPU.

## Target-only versus DSpark

- **Target-only:** `Ternary-Bonsai-27B-Q2_0.gguf` is the actual language model and generates each token itself.
- **With DSpark:** `Ternary-Bonsai-27B-dspark-Q4_1.gguf` proposes four-token blocks, but the Q2_0 target still verifies the output. The drafter cannot run independently.

At `ctx=262144`, the current DSpark server path raises its physical draft batch to 262,148 positions and attempts a roughly 161 GB CUDA compute allocation. This fails even though the target and q4_0 KV cache fit in about 13.2 GiB. It is a full-context staging limitation, not normal model or KV-cache usage, so the full-context launcher runs target-only.
