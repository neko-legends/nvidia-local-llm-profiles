# DeepReinforce Ornith 1.0 35B GGUF Q5_K_M

Model: `deepreinforce-ai/Ornith-1.0-35B-GGUF`

File:

- `ornith-1.0-35b-Q5_K_M.gguf`

Runtime:

- llama.cpp CUDA
- Local endpoint: `http://127.0.0.1:39189/v1`
- Model id: `ornith-1.0-35b-q5-k-m`
- Context profile: `262144`
- KV cache: `q4_0` keys and values

Run:

```bat
download-ornith-1.0-35b-q5-k-m.bat
start-ornith-1.0-35b-q5-k-m-server.bat
bench-ornith-1.0-35b-q5-k-m-two-point.bat
```

The benchmark wrapper uses the saved prompt fixtures:

- `benchmarks/prompts/book-context-10k.txt`
- `benchmarks/prompts/book-context-200k.txt`

Ornith is a reasoning model, so these scripts leave llama.cpp reasoning mode on
by default. For no-think latency experiments, run the PowerShell benchmark with
`-NoThinking` or set `THINKING=0` in the foreground server script.
