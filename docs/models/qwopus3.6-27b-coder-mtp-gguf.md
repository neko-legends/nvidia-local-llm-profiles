# Qwopus3.6 27B Coder MTP GGUF

Model:

- Hugging Face repo: `Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF`
- File: `Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf`
- Format: GGUF with MTP
- Runtime: llama.cpp CUDA

> **Hugging Face account may be required.** If download fails with a 401 or
> auth error, run `huggingface-cli login` and accept any license on the model page.
> Install the CLI with: `pip install -U "huggingface_hub[cli]"`

Launcher pack:

```text
scripts\localai\qwopus3.6-27b-coder-mtp-gguf\
```

Install into your LocalAI folder:

```text
scripts\localai\qwopus3.6-27b-coder-mtp-gguf\install-to-LocalAI.bat
```

Download model (after installing):

```text
download-qwopus3.6-27B-Coder-MTP-Q5.bat
```

Start:

```text
start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Edit `LLAMA_DIR` in that script to point at your llama.cpp CUDA build.
Download releases from: https://github.com/ggml-org/llama.cpp/releases

Hermes:

- Desktop base URL: `http://127.0.0.1:39182/v1`
- LAN base URL: `http://<your-server-lan-ip>:39182/v1`
- Model: `qwopus3.6-27b-coder-mtp-q5-k-m`

Serving choices:

- Primary CUDA GPU only: `--device CUDA0`
- Full GPU offload: `--gpu-layers all`
- Context: `--ctx-size 262144`
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- Flash attention: `--flash-attn on`
- MTP + ngram speculative decoding: `--spec-type ngram-mod,draft-mtp --spec-draft-n-max 2`
- Thinking mode: `--reasoning off` (no CoT) or `--reasoning on`

The default context is the RTX 5090 benchmark profile. Edit `CTX_SIZE` only when
recording a lower-context comparison or if startup fails.

Thinking mode: the model card benchmarks Qwopus in no-thinking mode (SWE-bench
Verified 67% at ~100 tok/s). The launcher defaults to `THINKING=0`
(`--reasoning off`) so the model goes straight to answers with no CoT preamble,
matching how the model card benchmarks Qwopus for fast local agentic coding.
Toggle to `THINKING=1` at the top of the launcher to re-enable reasoning blocks.