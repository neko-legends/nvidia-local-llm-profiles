# Qwopus3.6 27B Coder MTP GGUF

Model:

- Hugging Face repo: `Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF`
- Expected file: `D:\Tools\LocalAI\models\Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf`
- Format: GGUF with MTP
- Runtime: llama.cpp CUDA

Launcher pack:

```text
scripts\localai\qwopus3.6-27b-coder-mtp-gguf
```

Install into LocalAI:

```text
scripts\localai\qwopus3.6-27b-coder-mtp-gguf\install-to-LocalAI.bat
```

Start:

```text
D:\Tools\LocalAI\start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Hermes:

- Desktop base URL: `http://127.0.0.1:39182/v1`
- LAN base URL: `http://192.168.68.73:39182/v1`
- Tailscale base URL: `http://100.64.131.86:39182/v1`
- Model: `qwopus3.6-27b-coder-mtp-q5-k-m`

Serving choices:

- Uses RTX 5090 only: `--device CUDA0`
- Full GPU offload: `--gpu-layers all`
- Context: `--ctx-size 262144`
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- Flash attention: `--flash-attn on`
- MTP + ngram speculative decoding: `--spec-type ngram-mod,draft-mtp --spec-draft-n-max 2`

The default context is the RTX 5090 benchmark profile so the repo can test 100K and 200K prompt-token targets. Edit `CTX_SIZE` only when recording a lower-context comparison or if startup fails.
