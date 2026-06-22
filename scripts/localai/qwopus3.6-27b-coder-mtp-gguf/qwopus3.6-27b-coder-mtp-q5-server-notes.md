# Qwopus3.6 27B Coder MTP Q5 local server

Model:

- Hugging Face repo: `Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF`
- File: `Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf`
- Runtime: llama.cpp CUDA (`llama-server.exe`)

Download the model:

```text
download-qwopus3.6-27B-Coder-MTP-Q5.bat
```

> **Hugging Face account may be required.** If the download fails with a
> 401 or authentication error, log in first with `huggingface-cli login`
> and accept any license on the model page. Install the CLI with:
> `pip install -U "huggingface_hub[cli]"`

Start:

```text
start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Before starting, edit `LLAMA_DIR` in that script to point at your
llama.cpp CUDA build. Download pre-built releases from:
https://github.com/ggml-org/llama.cpp/releases

If Hermes Client cannot connect remotely, run `allow-qwopus3.6-coder-mtp-server-firewall-admin.bat`
once and accept the UAC prompt.

Hermes settings:

- Provider type/API: OpenAI-compatible chat completions
- Desktop base URL: `http://127.0.0.1:39182/v1`
- LAN base URL: `http://<your-server-lan-ip>:39182/v1`
- API key: empty, `none`, or any placeholder if Hermes requires one
- Model: `qwopus3.6-27b-coder-mtp-q5-k-m`

Current serving choices:

- Uses only the primary CUDA GPU: `--device CUDA0`
- Full GPU offload: `--gpu-layers all`
- Context: `--ctx-size 262144`
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- Flash attention: `--flash-attn on`
- One server slot: `--parallel 1`
- MTP + ngram speculative decoding: `--spec-type ngram-mod,draft-mtp --spec-draft-n-max 2`

The default context is the RTX 5090 benchmark profile. If startup fails or
VRAM pressure is too high, edit `CTX_SIZE` in the batch file to a lower value
(e.g. `65536` or `32768`) and record the lower value in your benchmark notes.
