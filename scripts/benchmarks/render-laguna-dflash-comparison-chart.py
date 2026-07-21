from pathlib import Path
import csv

import matplotlib.pyplot as plt


ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = ROOT / "results" / "rtx-5090" / "laguna-xs-2.1-dflash-comparison-20260721.csv"
OUT_DIR = ROOT / "assets" / "images"
COLORS = {"plain llama.cpp": "#6f7b91", "Lucebox DFlash + KVFlash": "#ff5aa7"}


with CSV_PATH.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))

contexts = ["10k", "200k"]
runtimes = ["plain llama.cpp", "Lucebox DFlash + KVFlash"]
lookup = {(row["context_target"], row["runtime"]): row for row in rows}

plt.style.use("dark_background")
fig, axes = plt.subplots(1, 2, figsize=(13.5, 6.2), facecolor="#090d16")
fig.suptitle("RTX 5090 · Poolside Laguna XS 2.1 Q4_K_M · CodeContext A/B", fontsize=18, fontweight="bold", y=0.97)
fig.text(0.5, 0.915, "Same checked-in prompt text and SHA per context; lower request time and higher decode speed are better.", ha="center", color="#aeb8cc", fontsize=10)

for ax in axes:
    ax.set_facecolor("#0f1522")
    ax.grid(axis="y", color="#293249", alpha=0.65, linewidth=0.8)
    ax.set_axisbelow(True)
    for spine in ax.spines.values():
        spine.set_color("#293249")

x = range(len(contexts))
width = 0.36
for index, runtime in enumerate(runtimes):
    offset = (index - 0.5) * width
    wall = [float(lookup[(context, runtime)]["wall_seconds"]) for context in contexts]
    decode = [float(lookup[(context, runtime)]["decode_tps"]) for context in contexts]
    bars = axes[0].bar([position + offset for position in x], wall, width, label=runtime, color=COLORS[runtime])
    axes[0].bar_label(bars, fmt="%.1fs", padding=4, fontsize=9)
    bars = axes[1].bar([position + offset for position in x], decode, width, label=runtime, color=COLORS[runtime])
    axes[1].bar_label(bars, fmt="%.1f", padding=4, fontsize=9)

axes[0].set_title("Full request wall time", fontsize=13, pad=12)
axes[0].set_ylabel("Seconds")
axes[1].set_title("Generation / decode throughput", fontsize=13, pad=12)
axes[1].set_ylabel("Tokens per second")
for ax in axes:
    ax.set_xticks(list(x), ["10K fixture", "200K fixture"])

axes[0].legend(loc="upper left", frameon=False)
axes[1].text(0.98, 0.04, "DFlash acceptance\n10K: 56.2% · 200K: 54.4%", transform=axes[1].transAxes, ha="right", va="bottom", color="#aeb8cc", fontsize=9)
fig.text(0.5, 0.025, "DFlash tokenizer accounting: 9,351 / 185,357 prompt tokens; llama.cpp: 10,057 / 199,455. DFlash uses KVFlash 8192 + FA window 2048.", ha="center", color="#8793aa", fontsize=9)
fig.subplots_adjust(left=0.07, right=0.98, top=0.84, bottom=0.14, wspace=0.22)

OUT_DIR.mkdir(parents=True, exist_ok=True)
for suffix in ("png", "svg"):
    output_path = OUT_DIR / f"rtx-5090-laguna-dflash-code-context.{suffix}"
    fig.savefig(output_path, dpi=180 if suffix == "png" else None, facecolor=fig.get_facecolor())
    if suffix == "svg":
        svg = output_path.read_text(encoding="utf-8")
        output_path.write_text("\n".join(line.rstrip() for line in svg.splitlines()) + "\n", encoding="utf-8")
plt.close(fig)
