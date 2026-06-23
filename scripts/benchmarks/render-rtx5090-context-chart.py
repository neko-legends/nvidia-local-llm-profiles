from __future__ import annotations

import csv
import math
from pathlib import Path

import matplotlib.patheffects as pe
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker


ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = ROOT / "results" / "rtx-5090"
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_BASENAME = "rtx-5090-context-ladder-comparison"

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
        "name": "Qwopus Coder Q5",
        "runtime": "llama.cpp b9761, ctx 256k, MTP n=2",
        "glob": "qwopus-coder-mtp-q5-ctx256k-mtp-prompt*-gen1024-*.csv",
        "color": "#39d6c7",
        "edge": "#bff8f1",
    },
    {
        "name": "AEON NVFP4 XS",
        "runtime": "vLLM, fp8 KV, ctx 200k, qwen3_5_mtp",
        "glob": "aeon-qwen36-27b-multimodal-nvfp4-mtp-xs-vllm-fp8kv-ctx200k-prompt*-gen1024-*.csv",
        "color": "#ffbc42",
        "edge": "#ffe2a3",
    },
]

TEXT = "#eef3f6"
MUTED = "#a8b2bc"
GRID = "#303741"
BACKGROUND = "#101318"
PANEL = "#171b22"


def fnum(value: str | None) -> float:
    return float(value) if value not in ("", None) else math.nan


def context_label(tokens: int) -> str:
    return TARGET_LABELS.get(tokens, f"{round(tokens / 1000):.0f}k")


def load_series(pattern: str) -> dict[int, dict[str, float | int]]:
    candidates = sorted(RESULTS_DIR.glob(pattern))
    if not candidates:
        raise FileNotFoundError(f"No benchmark CSVs matched {pattern!r} in {RESULTS_DIR}")

    latest_by_target: dict[int, Path] = {}
    for path in candidates:
        with path.open(newline="", encoding="utf-8-sig") as handle:
            first = next(csv.DictReader(handle))
        target = int(first["target_prompt_tokens"])
        latest_by_target[target] = path

    rows: dict[int, dict[str, float | int]] = {}
    for per_run in latest_by_target.values():
        with per_run.open(newline="", encoding="utf-8-sig") as handle:
            measured = [
                row
                for row in csv.DictReader(handle)
                if row.get("warmup", "").lower() not in ("true", "1", "yes")
            ]

        tps = [fnum(row["wall_completion_tps"]) for row in measured]
        power = [fnum(row["power_after_w"]) for row in measured]
        temps = [fnum(row["temp_after_c"]) for row in measured]
        target = int(measured[0]["target_prompt_tokens"])
        rows[target] = {
            "target": target,
            "actual": max(int(row["prompt_tokens"]) for row in measured),
            "avg": sum(tps) / len(tps),
            "min": min(tps),
            "max": max(tps),
            "power": sum(power) / len(power),
            "temp": sum(temps) / len(temps),
        }

    return rows


def strip_trailing_whitespace(path: Path) -> None:
    cleaned = "\n".join(line.rstrip() for line in path.read_text(encoding="utf-8").splitlines())
    path.write_text(cleaned + "\n", encoding="utf-8")


def draw_chart() -> tuple[Path, Path]:
    series_rows = [load_series(series["glob"]) for series in SERIES]
    targets = sorted(set().union(*(rows.keys() for rows in series_rows)))
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "svg.fonttype": "none",
            "axes.unicode_minus": False,
        }
    )

    fig = plt.figure(figsize=(16, 9), dpi=180, facecolor=BACKGROUND)
    ax = fig.add_axes([0.12, 0.19, 0.79, 0.57], facecolor=PANEL)

    group_gap = 1.28
    bar_height = 0.33
    y_centers = [idx * group_gap for idx, _ in enumerate(targets)]
    offsets = [-bar_height / 1.7, bar_height / 1.7]

    for series_index, series in enumerate(SERIES):
        rows = series_rows[series_index]
        color = series["color"]
        edge = series["edge"]
        for target_index, target in enumerate(targets):
            row = rows.get(target)
            if row is None:
                continue

            y = y_centers[target_index] + offsets[series_index]
            avg = float(row["avg"])
            low = float(row["min"])
            high = float(row["max"])

            ax.barh(
                y,
                avg,
                height=bar_height,
                color=color,
                edgecolor=edge,
                linewidth=0.9,
                alpha=0.94,
                zorder=3,
            )
            ax.hlines(y, low, high, color="#f8fbff", linewidth=1.7, alpha=0.72, zorder=5)
            ax.scatter([low, high], [y, y], s=20, color=PANEL, edgecolor="#f8fbff", linewidth=0.9, zorder=6)
            ax.text(
                avg + 2.0,
                y,
                f"{avg:.1f}",
                va="center",
                ha="left",
                color=TEXT,
                fontsize=11.5,
                fontweight="bold",
                path_effects=[pe.withStroke(linewidth=3, foreground=PANEL)],
                zorder=8,
            )

    y_labels = []
    for target in targets:
        actuals = [rows[target]["actual"] for rows in series_rows if target in rows]
        actual = max(int(value) for value in actuals)
        y_labels.append(f"{context_label(target)}\n{actual:,} prompt toks")

    ax.set_yticks(y_centers)
    ax.set_yticklabels(y_labels, fontsize=11.2, color=TEXT)
    ax.invert_yaxis()

    ax.set_xlim(0, 135)
    ax.xaxis.set_major_locator(mticker.MultipleLocator(25))
    ax.xaxis.set_major_formatter(mticker.StrMethodFormatter("{x:.0f}"))
    ax.tick_params(axis="x", colors=MUTED, labelsize=10.5)
    ax.tick_params(axis="y", length=0)
    ax.grid(axis="x", color=GRID, alpha=0.75, linewidth=0.8, zorder=1)
    for spine in ax.spines.values():
        spine.set_visible(False)

    legend_x = 0.065
    for idx, series in enumerate(SERIES):
        y = 0.806 - idx * 0.043
        fig.text(
            legend_x,
            y,
            "  ",
            ha="left",
            va="center",
            bbox={
                "boxstyle": "round,pad=0.22,rounding_size=0.10",
                "facecolor": series["color"],
                "edgecolor": series["edge"],
            },
        )
        fig.text(legend_x + 0.029, y, series["name"], ha="left", va="center", color=TEXT, fontsize=12.0, fontweight="bold")
        fig.text(legend_x + 0.178, y, series["runtime"], ha="left", va="center", color=MUTED, fontsize=11.0)

    fig.text(
        0.065,
        0.91,
        "RTX 5090 long-context throughput",
        ha="left",
        va="center",
        color=TEXT,
        fontsize=29,
        fontweight="bold",
    )
    fig.text(
        0.065,
        0.858,
        "1024 generated tokens, temperature 0, 3 measured runs per context. Bars are averages; rails show min/max.",
        ha="left",
        va="center",
        color="#cad5de",
        fontsize=13.0,
    )
    fig.text(
        0.065,
        0.094,
        "Source: results/rtx-5090 CSVs, 2026-06-22 to 2026-06-23. AEON was served with max_model_len=200k.",
        ha="left",
        va="center",
        color="#89939e",
        fontsize=10.5,
    )
    fig.text(
        0.94,
        0.094,
        "neko-legends/nvidia-local-llm-profiles",
        ha="right",
        va="center",
        color="#89939e",
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
