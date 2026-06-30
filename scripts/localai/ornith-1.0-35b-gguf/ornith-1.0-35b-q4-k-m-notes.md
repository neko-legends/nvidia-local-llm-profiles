# DeepReinforce Ornith 1.0 35B GGUF

Model: `deepreinforce-ai/Ornith-1.0-35B-GGUF`

File:

- `ornith-1.0-35b-Q4_K_M.gguf`

Runtime:

- llama.cpp CUDA
- Local endpoint: `http://127.0.0.1:39188/v1`
- Model id: `ornith-1.0-35b-q4-k-m`
- Context profile: `262144`
- KV cache: `q4_0` keys and values

Run:

```bat
download-ornith-1.0-35b-q4-k-m.bat
start-ornith-1.0-35b-q4-k-m-server.bat
bench-ornith-1.0-35b-q4-k-m-two-point.bat
```

The benchmark wrapper uses the saved prompt fixtures:

- `benchmarks/prompts/book-context-10k.txt`
- `benchmarks/prompts/book-context-200k.txt`

Ornith is a reasoning model, so these scripts leave llama.cpp reasoning mode on
by default. For no-think latency experiments, run the PowerShell benchmark with
`-NoThinking` or set `THINKING=0` in the foreground server script.

RTX 5090 quick benchmark:

| Context target | Prompt tokens | Generation tok/s | Prompt read / prefill | Full-request tok/s |
| ---: | ---: | ---: | ---: | ---: |
| 10k reference | 8,905 | 184.5 warm avg | 1.7s cold | 181.0 warm wall |
| 200k reference | 174,588 | 106.7 | 40.3s | 20.3 |

The 2026-06-30 10k rerun replaced the older 201.5 tok/s single-run chart value.
The current 10k generation number uses the warm repeat average from runs 2-3:
184.14 and 184.76 tok/s. The 200k prompt read time is from the 2026-06-25
sequential two-point wrapper, so llama.cpp reused the prefix cached by the
preceding 10k run and processed 166,199 new prompt tokens. The full-request
tok/s column is completion tokens divided by end-to-end request wall time.

Manual Unsloth Studio observations:

| Context | Generated tokens | UI speed | Prompt read | Total |
| ---: | ---: | ---: | ---: | ---: |
| 9.5k inferred | 2,523 | 127.2 tok/s | 1.75s | 22.65s |
| 175.2k inferred | 3,281 | 89.9 tok/s | 39.69s | 77.29s |

The Studio context values are inferred from prompt eval seconds times prompt
speed in the screenshots.

Long-context proof:

![Ornith 1.0 35B GGUF in Unsloth Studio at 89.9 tok/s near 175k context](../../../assets/images/ornith-unsloth-studio-175k-proof.png)
