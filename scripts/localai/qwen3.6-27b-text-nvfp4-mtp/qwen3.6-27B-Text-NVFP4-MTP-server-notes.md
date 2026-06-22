# Qwen3.6 27B Text NVFP4 MTP local server

Model:

- Hugging Face repo: `sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP`
- Format: ModelOpt NVFP4 safetensors with bf16 MTP head
- Runtime: vLLM Docker (`vllm/vllm-openai`)

Download the model:

```text
download-qwen3.6-27B-Text-NVFP4-MTP.bat
```

> **Hugging Face account may be required.** If the download fails with a
> 401 or authentication error, log in first with `huggingface-cli login`
> and accept any license on the model page. Install the CLI with:
> `pip install -U "huggingface_hub[cli]"`

Start the server:

```text
start-qwen3.6-27B-Text-NVFP4-MTP-server.bat
```

Or directly with the PowerShell launcher (supports parameter overrides):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "Start-Qwen3.6-27B-Text-NVFP4-MTP-vLLM.ps1"
```

Hermes settings:

- Provider type/API: OpenAI-compatible chat completions
- Base URL: `http://127.0.0.1:8892/v1`
- API key: empty, `none`, or any placeholder if Hermes requires one
- Model: `qwen3.6-27b-text-nvfp4-mtp`
- Provider shortcut: `custom:qwen36-text-nvfp4-mtp-local`

Current serving choices:

- Docker image: `vllm/vllm-openai:latest`
- Default context: `262144`
- Default slots: `1`
- Quantization: `--quantization modelopt`
- Text-only mode: `--language-model-only`
- Reasoning parser: `--reasoning-parser qwen3`
- MTP speculative decoding: `{"method":"qwen3_5_mtp","num_speculative_tokens":3}`

Lower-context fallback (if 256K startup fails):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "Start-Qwen3.6-27B-Text-NVFP4-MTP-vLLM.ps1" -MaxModelLen 32768
```

The default is the RTX 5090 256K context benchmark profile. Lower `-MaxModelLen`
only when recording a lower-context comparison or if startup fails.
