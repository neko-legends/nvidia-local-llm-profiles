# RTX 5090 Power And Thermal Notes

The RTX 5090 is the first max-performance tuning target for this repo. Agents should treat power and thermal setup as part of the benchmark recipe, not as optional desktop state.

![RTX 5090 MSI Afterburner voltage/frequency curve](../../assets/images/rtx-5090-msi-afterburner-vf-curve.png)

## Required Before Long Runs

Apply the saved MSI Afterburner voltage/frequency curve before long inference, benchmark sweeps, or unattended Hermes usage on the RTX 5090.

Why this matters:

- Long inference is a sustained load, unlike short gaming bursts.
- Stock boost behavior can waste power for little throughput gain.
- This machine has seen long-run overheating or shutdown behavior without a controlled curve.
- Stable power behavior makes benchmark CSVs comparable across runs.

The screenshot is the reference visual for the local operating profile. It shows MSI Afterburner with the RTX 5090 selected, a reduced power-limit style setup, and a flattened voltage/frequency curve. Do not blindly transfer the exact curve to another card without a stability check.

## Local GPU Inventory

Current `nvidia-smi` snapshot from this machine:

```text
GPU 0: NVIDIA GeForce RTX 5090, driver 610.62, power limit 546.25 W, memory 32607 MiB
GPU 1: NVIDIA GeForce RTX 3090, driver 610.62, power limit 378.00 W, memory 24576 MiB
```

Use GPU `0` for RTX 5090-focused benchmark runs unless a script explicitly says otherwise.

## Agent Checklist

Before a 5090 benchmark:

- Confirm the model server is targeting `CUDA0` or GPU index `0`.
- Confirm the Afterburner curve profile is applied.
- Confirm `nvidia-smi` sees the RTX 5090 as GPU `0`.
- Record the model file or Hugging Face repo.
- Record exact launch settings such as context, KV cache, speculative decoding, batch settings, and runtime.
- Record power and temperature before and after each measured run.

If the system shuts down, throttles hard, or shows unstable clocks, stop benchmarking and treat the power curve or cooling state as the first suspect.
