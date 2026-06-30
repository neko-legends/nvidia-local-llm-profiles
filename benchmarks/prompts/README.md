# Benchmark prompts

These files are deterministic prompt fixtures used when comparing local model
profiles. Keeping the prompt text in the repo makes short-context reruns
and long-context reruns comparable across quantizations and runtimes.

## book-context-10k.txt

- Generator: `scripts/benchmarks/bench-openai-chat-endpoint.ps1`
- Style: `BookContext`
- Target: `10000` prompt tokens
- Characters: `42940`
- SHA256: `785c5b31d1ce77612431b1289c0a097ed51ab1a6d4a07bccfb7a70f59df55f94`
- Used for: Qwopus Q4_K_M and Qwopus Q5_K_M 10k reference comparisons

## book-context-200k.txt

- Generator: `scripts/benchmarks/bench-openai-chat-endpoint.ps1`
- Style: `BookContext`
- Target: `200000` prompt tokens
- Characters: `840403`
- SHA256: `a794ca243983eb3387bec6728db4b0c72a99ee2a98cfee7223269708e4ae228c`
- Used for: 200k reference comparisons across Qwopus, Unsloth 35B, and NVIDIA NVFP4 runs

## book-context-300k.txt

- Generator: `scripts/benchmarks/bench-openai-chat-endpoint.ps1`
- Style: `BookContext`
- Target: `300000` prompt tokens
- Characters: `1260986`
- SHA256: `5e3a5f9c15da85d938993ef0c80153d26ba405a13689447fd7082d23355ca4ba`
- Used for: NVIDIA Qwen3.6 NVFP4 GGUF max-context stress checks. On the
  Qwen3.6 35B A3B NVFP4 GGUF, this tokenizes to 261,960 prompt tokens and
  reaches the 262,144-token context cap.

Regenerate:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\benchmarks\bench-openai-chat-endpoint.ps1 `
  -PromptStyle BookContext `
  -TargetPromptTokens 10000 `
  -PromptOutFile benchmarks\prompts\book-context-10k.txt `
  -PromptOnly
```

Regenerate the 200k fixture:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\benchmarks\bench-openai-chat-endpoint.ps1 `
  -PromptStyle BookContext `
  -TargetPromptTokens 200000 `
  -PromptOutFile benchmarks\prompts\book-context-200k.txt `
  -PromptOnly
```

Regenerate the 300k fixture:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\benchmarks\bench-openai-chat-endpoint.ps1 `
  -PromptStyle BookContext `
  -TargetPromptTokens 300000 `
  -PromptOutFile benchmarks\prompts\book-context-300k.txt `
  -PromptOnly
```

Benchmark from the saved prompt:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\benchmarks\bench-openai-chat-endpoint.ps1 `
  -BaseUrl http://127.0.0.1:39182/v1 `
  -Model qwopus3.6-27b-coder-mtp-q5-k-m `
  -PromptFile benchmarks\prompts\book-context-10k.txt `
  -PromptStyle BookContext `
  -TargetPromptTokens 10000 `
  -MaxTokens 1024
```
