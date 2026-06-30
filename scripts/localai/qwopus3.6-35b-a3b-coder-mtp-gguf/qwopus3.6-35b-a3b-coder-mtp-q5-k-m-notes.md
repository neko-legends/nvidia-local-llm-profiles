# Qwopus3.6 35B A3B Coder MTP Q5_K_M local server

- Hugging Face repo: `Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF`
- File: `Qwopus3.6-35B-A3B-Coder-MTP-Q5_K_M.gguf`
- Runtime: native Windows `llama.cpp` CUDA (`llama-server.exe`)
- Default endpoint: `http://127.0.0.1:39191/v1`
- Default model id: `qwopus3.6-35b-a3b-coder-mtp-q5-k-m`
- Default context: `200000`

The launcher uses q4 target and draft KV cache, flash attention, and pure
`draft-mtp` speculative decoding with `--spec-draft-n-max 2`. That was the best
RTX 5090 long-context profile measured so far: it was slightly slower than the
old `ngram-mod,draft-mtp` profile at 10k, but faster at 200k.

The benchmark wrapper also accepts `-SpecDraftNMax 3` and
`-SpecType ngram-mod,draft-mtp` for quick sweeps. On RTX 5090, Q5 n=3 was faster
at the 10k prompt but slower at the 200k prompt, so n=2 remains the default
long-context profile.

The model is downloaded to the repo checkout parent:

```text
<checkout-parent>\.local-model-cache\Jackrong\Qwopus3.6-35B-A3B-Coder-MTP-GGUF\
```

Set `LLAMA_DIR` to your llama.cpp CUDA build folder, or put `llama-server.exe`
on `PATH`, before running the start script.
