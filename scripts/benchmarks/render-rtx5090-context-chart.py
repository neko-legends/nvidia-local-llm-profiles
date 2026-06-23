from __future__ import annotations

import csv
import math
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker


ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = ROOT / "results" / "rtx-5090"
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_BASENAME = "rtx-5090-context-ladder-comparison"

BACKGROUND = "#111418"
PANEL = "#191e25"
TEXT = "#eef3f6"
MUTED = "#a7b0ba"
GRID = "#303842"

TARGET_LABELS = {
    8192: "8k",
    32768: "33k",
    65536: "66k",
    131072: "131k",
    200000: "200k",
    262144: "256k",
}

SERIES = [
    {
        "title": "Qwopus Coder Q5",
        "subtitle": "llama.cpp b9761 / ctx 256k / MTP n=2",
        "glob": "qwopus-coder-mtp-q5-ctx256k-mtp-prompt*-gen1024-*.csv",
        "color": "#43d3c5",
        "edge": "#b9fbf4",
    },
    {
        "title": "AEON NVFP4 XS",
        "subtitle": "vLLM / fp8 KV / ctx 200k / qwen3_5_mtp",
        "glob": "aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-fp8kv-ctx200k-prompt*-gen1024-*.csv",
        "color": "#ffbb42",
        "edge": "#ffe4aa",
    },
]


def fnum(value: str | None) -> float:
    return float(value) if value not in ("", None) else math.nan


def context_label(tokens: int) -> str:
    return TARGET_LABELS.get(tokens, f"{round(tokens / 1000):.0f}k")


def load_series(pattern: str) -> list[dict[str, float | int | str]]:
    candidates = sorted(RESULTS_DIR.glob(pattern))
    if not candidates:
        raise FileNotFoundError(f"No benchmark CSVs matched {pattern!r} in {RESULTS_DIR}")

    latest_by_target: dict[int, Path] = {}
    for path in candidates:
        with path.open(newline="", encoding="utf-8-sig") as handle:
            first = next(csv.DictReader(handle))
        latest_by_target[int(first["target_prompt_tokens"])] = path

    rows: list[dict[str, float | int | str]] = []
    for target, per_run in latest_by_target.items():
        with per_run.open(newline="", encoding="utf-8-sig") as handle:
            measured = [
                row
                for row in csv.DictReader(handle)
                if row.get("warmup", "").lower() not in ("true", "1", "yes")
            ]

        tps = [fnum(row["wall_completion_tps"]) for row in measured]
        rows.append(
            {
                "target": target,
                "label": context_label(target),
                "avg": sum(tps) / len(tps),
            }
        )

    return sorted(rows, key=lambda row: int(row["target"]))


def strip_trailing_whitespace(path: Path) -> None:
    cleaned = "\n".join(line.rstrip() for line in path.read_text(encoding="utf-8").splitlines())
    path.write_text(cleaned + "\n", encoding="utf-8")


def style_axis(ax: plt.Axes) -> None:
    ax.set_facecolor(PANEL)
    ax.set_xlim(0, 125)
    ax.xaxis.set_major_locator(mticker.MultipleLocator(25))
    ax.xaxis.set_major_formatter(mticker.StrMethodFormatter("{x:.0f}"))
    ax.grid(axis="x", color=GRID, alpha=0.72, linewidth=0.85)
    ax.set_axisbelow(True)
    ax.tick_params(axis="x", colors=MUTED, labelsize=10)
    ax.tick_params(axis="y", colors=TEXT, labelsize=13, length=0, pad=8)
    for spine in ax.spines.values():
        spine.set_visible(False)


def draw_panel(ax: plt.Axes, series: dict[str, str], rows: list[dict[str, float | int | str]]) -> None:
    labels = [str(row["label"]) for row in rows]
    values = [float(row["avg"]) for row in rows]
    y_positions = list(range(len(rows)))

    ax.barh(
        y_positions,
        values,
        height=0.58,
        color=series["color"],
        edgecolor=series["edge"],
        linewidth=1.2,
        alpha=0.97,
    )

    for y, value in zip(y_positions, values):
        ax.text(
            value + 1.7,
            y,
            f"{value:.1f}",
            ha="left",
            va="center",
            color=TEXT,
            fontsize=13,
            fontweight="bold",
        )

    ax.set_yticks(y_positions)
    ax.set_yticklabels(labels)
    ax.invert_yaxis()
    ax.set_xlabel("avg completion tok/s", color=MUTED, fontsize=10.5, labelpad=10)
    ax.text(0, -1.22, series["title"], ha="left", va="center", color=TEXT, fontsize=18, fontweight="bold")
    ax.text(0, -0.86, series["subtitle"], ha="left", va="center", color=MUTED, fontsize=11)


def draw_chart() -> tuple[Path, Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows_by_series = [load_series(series["glob"]) for series in SERIES]

    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "svg.fonttype": "none",
            "axes.unicode_minus": False,
        }
    )

    fig = plt.figure(figsize=(16, 9), dpi=180, facecolor=BACKGROUND)
    left_ax = fig.add_axes([0.075, 0.18, 0.405, 0.57])
    right_ax = fig.add_axes([0.545, 0.18, 0.405, 0.57])

    for ax, series, rows in zip((left_ax, right_ax), SERIES, rows_by_series):
        style_axis(ax)
        draw_panel(ax, series, rows)

    fig.text(
        0.075,
        0.91,
        "RTX 5090 long-context throughput",
        ha="left",
        va="center",
        color=TEXT,
        fontsize=30,
        fontweight="bold",
    )
    fig.text(
        0.075,
        0.855,
        "Average completion tokens per second. 1024 generated tokens, temperature 0, three measured runs per context.",
        ha="left",
        va="center",
        color="#ccd5de",
        fontsize=13.5,
    )
    fig.text(
        0.075,
        0.095,
        "Source: results/rtx-5090 CSVs, 2026-06-22 to 2026-06-23. AEON was served with max_model_len=200k.",
        ha="left",
        va="center",
        color="#8e98a3",
        fontsize=10.5,
    )
    fig.text(
        0.95,
        0.095,
        "neko-legends/nvidia-local-llm-profiles",
        ha="right",
        va="center",
        color="#8e98a3",
        fontsize=10.5,
    )

    png_path = OUTPUT_DIR / f"{OUTPUT_BASENAME}.png"
    svg_path = OUTPUT_DIR / f"{OUTPUT_BASENAME}.svg"
    fig.savefig(png_path, facecolor=fig.get_facecolor(), dpi=180)
    fig.savefig(svg_path, facecolor=fig.get_facecolor())
    plt.close(fig)
    strip_trailing_whitespace(svg_path)
    return png_path, svg_path


if __name__ == "__main__":
    png, svg = draw_chart()
    print(png)
    print(svg)
