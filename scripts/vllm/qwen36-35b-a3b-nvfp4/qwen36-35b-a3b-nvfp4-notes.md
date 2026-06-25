# NVIDIA Qwen3.6 35B A3B NVFP4

Model: `nvidia/Qwen3.6-35B-A3B-NVFP4`

This is the pre-quantized ModelOpt NVFP4 MoE checkpoint from NVIDIA. The model
card lists vLLM as the supported runtime and Linux as the preferred OS, so this
Windows profile uses Docker Desktop with `vllm/vllm-openai:nightly`.

Local endpoint:

- Base URL: `http://127.0.0.1:39184/v1`
- Model: `qwen36-35b-a3b-nvfp4`

Run:

```bat
start-qwen36-35b-a3b-nvfp4-vllm-docker.bat
bench-qwen36-35b-a3b-nvfp4-two-point.bat
```

The benchmark script only runs two measured contexts: about 10k and 200k prompt
tokens.

RTX 5090 quick benchmark:

| Context target | Prompt tokens | tok/s | Power | Temp |
| ---: | ---: | ---: | ---: | ---: |
| 10k reference | 8,905 | 92.0 | 172W | 48C |
| 200k reference | 174,588 | 30.5 | 231W | 56C |
