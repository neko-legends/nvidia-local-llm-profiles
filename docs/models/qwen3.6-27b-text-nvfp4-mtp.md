# Qwen3.6 27B Text NVFP4 MTP

Model:

- Hugging Face repo: `sakamakismile/Qwen3.6-27B-Text-NVFP4-MTP`
- Format: ModelOpt NVFP4 safetensors with MTP
- Runtime: vLLM Docker

> **Hugging Face account may be required.** If download fails with a 401 or
> auth error, run `huggingface-cli login` and accept any license on the model page.
> Install the CLI with: `pip install -U "huggingface_hub[cli]"`

Launcher pack:

```text
scripts\localai\qwen3.6-27b-text-nvfp4-mtp\
```

Install into your LocalAI folder:

```text
scripts\localai\qwen3.6-27b-text-nvfp4-mtp\install-to-LocalAI.bat
```

Download model (after installing):

```text
download-qwen3.6-27B-Text-NVFP4-MTP.bat
```

Start:

```text
start-qwen3.6-27B-Text-NVFP4-MTP-server.bat
```

Hermes:

- Base URL: `http://127.0.0.1:8892/v1`
- Model: `qwen3.6-27b-text-nvfp4-mtp`

Serving choices:

- Docker image: `vllm/vllm-openai:latest`
- Quantization: `--quantization modelopt`
- Text-only mode: `--language-model-only`
- Default context: `262144`
- KV cache dtype: `fp8`
- MTP speculative config: `{"method":"qwen3_5_mtp","num_speculative_tokens":3}`

The default context is the RTX 5090 256K benchmark profile. Use the PowerShell
launcher's `-MaxModelLen`, `-MaxNumSeqs`, and `-KvCacheDtype` parameters for
lower-context comparisons or fallback runs.
