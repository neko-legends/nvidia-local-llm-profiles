# Qwopus3.6 35B A3B Coder MTP Q4_K_M local server

- Hugging Face repo: `Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF`
- File: `Qwopus3.6-35B-A3B-Coder-MTP-Q4_K_M.gguf`
- Runtime: native Windows `llama.cpp` CUDA (`llama-server.exe`)
- Default endpoint: `http://127.0.0.1:39193/v1`
- Default model id: `qwopus3.6-35b-a3b-coder-mtp-q4-k-m`
- Default context: `200000`

The launcher uses q4 target and draft KV cache, flash attention, and
`ngram-mod,draft-mtp` speculative decoding with `--spec-draft-n-max 2` by
default. Set `SPEC_DRAFT_N_MAX=3` before the `.bat` launcher, or pass
`-SpecDraftNMax 3` to the benchmark wrapper, to try the Ryzen-style MTP depth.

The model is downloaded to the repo checkout parent:

```text
<checkout-parent>\.local-model-cache\Jackrong\Qwopus3.6-35B-A3B-Coder-MTP-GGUF\
```

Set `LLAMA_DIR` to your llama.cpp CUDA build folder, or put `llama-server.exe`
on `PATH`, before running the start script.
