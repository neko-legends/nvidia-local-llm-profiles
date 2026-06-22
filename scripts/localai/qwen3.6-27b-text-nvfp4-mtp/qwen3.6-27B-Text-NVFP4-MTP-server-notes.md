# Qwen3.6 27B Text NVFP4 MTP local server

Model:

- Hugging Face repo: `sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP`
- Local folder: `D:\Tools\LocalAI\models\Qwen3.6-27B-Text-NVFP4-MTP`
- Format: ModelOpt NVFP4 safetensors with bf16 MTP head

Start:

- Download first: `D:\Tools\LocalAI\download-qwen3.6-27B-Text-NVFP4-MTP.bat`
- From this repo, use: `D:\forPublic\nvidia-local-llm-profiles\scripts\localai\qwen3.6-27b-text-nvfp4-mtp\download-to-LocalAI-models.bat`
- Start Hermes server: `D:\Tools\LocalAI\start-qwen3.6-27B-Text-NVFP4-MTP-server.bat`

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

Lower-context fallback:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\Tools\LocalAI\Start-Qwen3.6-27B-Text-NVFP4-MTP-vLLM.ps1" -MaxModelLen 32768
```

The default is the RTX 5090 256K context benchmark profile so the repo can test 100K and 200K prompt-token targets. Lower `-MaxModelLen` only when recording a lower-context comparison or if startup fails.
