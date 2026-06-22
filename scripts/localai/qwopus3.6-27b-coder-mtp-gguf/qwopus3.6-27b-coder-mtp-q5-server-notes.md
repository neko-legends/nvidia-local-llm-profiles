# Qwopus3.6 27B Coder MTP Q5 local server

Model:

- Hugging Face repo: `Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF`
- Expected file: `D:\Tools\LocalAI\models\Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf`
- Runner: `D:\Tools\llama.cpp-b9267-cuda13.1\llama-server.exe`

Start:

- Double-click `D:\Tools\LocalAI\start-qwopus3.6-27b-coder-mtp-q5-server.bat`
- If Hermes Client cannot connect remotely, run `D:\Tools\LocalAI\allow-qwopus3.6-coder-mtp-server-firewall-admin.bat` once and accept the UAC prompt.

Hermes settings:

- Provider type/API: OpenAI-compatible chat completions
- Hermes Desktop base URL: `http://127.0.0.1:39182/v1`
- Hermes Client LAN base URL: `http://192.168.68.73:39182/v1`
- Hermes Client Tailscale base URL: `http://100.64.131.86:39182/v1`
- API key: empty, `none`, or any placeholder if Hermes requires one
- Model: `qwopus3.6-27b-coder-mtp-q5-k-m`

Current serving choices:

- Uses only the RTX 5090: `--device CUDA0`
- Full GPU offload: `--gpu-layers all`
- Context: `--ctx-size 262144`
- KV cache: `--cache-type-k q4_0 --cache-type-v q4_0`
- Flash attention: `--flash-attn on`
- One server slot: `--parallel 1`
- MTP + ngram speculative decoding: `--spec-type ngram-mod,draft-mtp --spec-draft-n-max 2`

The default context is the RTX 5090 benchmark profile so the repo can test 100K and 200K prompt-token targets. If startup fails or VRAM pressure is too high, edit `CTX_SIZE` in the batch file and record the lower value in the benchmark CSV notes.
