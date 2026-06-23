from __future__ import annotations

import csv
import math
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import matplotlib.patheffects as pe


ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = ROOT / "results" / "rtx-5090"
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_BASENAME = "rtx-5090-qwopus-context-ladder"

TARGET_LABELS = {
    8192: "8k",
    32768: "33k",
    65536: "66k",
    131072: "131k",
    200000: "200k",
    262144: "256k",
}

COLORS = ["#38d5c4", "#48d17f", "#f1c84b", "#ff9f45", "#ff6b6b", "#a78bfa"]
TEXT = "#eef3f6"
MUTED = "#9da8b2"
GRID = "#303741"
BACKGROUND = "#111419"
PANEL = "#171b22"


def fnum(value: str) -> float:
    return float(value) if value not in ("", None) else math.nan


def context_label(tokens: int) -> str:
    return TARGET_LABELS.get(tokens, f"{round(tokens / 1000):.0f}k")


def load_rows() -> list[dict[str, float | int | str]]:
    candidates = sorted(RESULTS_DIR.glob("qwopus-coder-mtp-q5-ctx256k-mtp-prompt*-gen1024-*.csv"))
    if not candidates:
        raise FileNotFoundError(f"No per-context benchmark CSVs found in {RESULTS_DIR}")

    latest_by_target: dict[int, Path] = {}
    for path in candidates:
        with path.open(newline="", encoding="utf-8-sig") as handle:
            first = next(csv.DictReader(handle))
        target = int(first["target_prompt_tokens"])
        latest_by_target[target] = path

    rows: list[dict[str, float | int | str]] = []
    for per_run in latest_by_target.values():
        with per_run.open(newline="", encoding="utf-8-sig") as handle:
            measured = [
                r
                for r in csv.DictReader(handle)
                if r.get("warmup", "").lower() not in ("true", "1", "yes")
            ]

        tps = [fnum(r["wall_completion_tps"]) for r in measured]
        power = [fnum(r["power_after_w"]) for r in measured]
        temps = [fnum(r["temp_after_c"]) for r in measured]
        target = int(measured[0]["target_prompt_tokens"])
        actual = max(int(r["prompt_tokens"]) for r in measured)
        rows.append(
            {
                "label": context_label(target),
                "target": target,
                "actual": actual,
                "avg": sum(tps) / len(tps),
                "min": min(tps),
                "max": max(tps),
                "power": sum(power) / len(power),
                "temp": sum(temps) / len(temps),
            }
        )

    return sorted(rows, key=lambda d: int(d["target"]))


def draw_chart() -> tuple[Path, Path]:
    rows = load_rows()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "svg.fonttype": "none",
            "axes.unicode_minus": False,
        }
    )

    fig = plt.figure(figsize=(16, 9), dpi=180, facecolor=BACKGROUND)
    ax = fig.add_axes([0.12, 0.19, 0.78, 0.56], facecolor=PANEL)

    y_positions = list(range(len(rows)))
    avgs = [float(row["avg"]) for row in rows]

    ax.barh(
        y_positions,
        avgs,
        height=0.62,
        color=COLORS[: len(rows)],
        edgecolor="#f7fbff",
        linewidth=0.8,
        alpha=0.96,
        zorder=3,
    )

    for idx, row in enumerate(rows):
        y = y_positions[idx]
        color = COLORS[idx]
        low = float(row["min"])
        high = float(row["max"])
        avg = float(row["avg"])

        ax.hlines(y, low, high, color="#f8fbff", linewidth=2.2, alpha=0.78, zorder=5)
        ax.scatter([low, high], [y, y], s=34, color=PANEL, edgecolor="#f8fbff", linewidth=1.2, zorder=6)
        ax.scatter([avg], [y], s=58, color=color, edgecolor="#111419", linewidth=1.4, zorder=7)

        ax.text(
            avg + 2.0,
            y,
            f"{avg:.1f} tok/s",
            va="center",
            ha="left",
            color=TEXT,
            fontsize=13,
            fontweight="bold",
            path_effects=[pe.withStroke(linewidth=3, foreground=PANEL)],
            zorder=8,
        )

        ax.text(
            135.5,
            y,
            f"{round(float(row['power']))}W  {round(float(row['temp']))}C",
            va="center",
            ha="left",
            color="#dce6ed",
            fontsize=10.5,
            bbox={
                "boxstyle": "round,pad=0.25,rounding_size=0.12",
                "facecolor": "#222833",
                "edgecolor": "#3b4652",
                "linewidth": 0.7,
            },
            zorder=9,
        )

    y_labels = [
        f"{row['label']}\n{int(row['actual']):,} prompt toks"
        for row in rows
    ]
    ax.set_yticks(y_positions)
    ax.set_yticklabels(y_labels, fontsize=11.5, color=TEXT)
    ax.invert_yaxis()

    ax.set_xlim(0, 150)
    ax.xaxis.set_major_locator(mticker.MultipleLocator(25))
    ax.xaxis.set_major_formatter(mticker.StrMethodFormatter("{x:.0f}"))
    ax.tick_params(axis="x", colors=MUTED, labelsize=10.5)
    ax.tick_params(axis="y", length=0)
    ax.grid(axis="x", color=GRID, alpha=0.75, linewidth=0.8, zorder=1)
    ax.set_axisbelow(True)
    for spine in ax.spines.values():
        spine.set_visible(False)

    ax.text(
        0,
        -0.86,
        "Run min-max rail",
        color="#c7d0d9",
        fontsize=10.5,
        ha="left",
        va="center",
    )
    ax.hlines(-0.86, 27, 43, color="#f8fbff", linewidth=2.2, alpha=0.78, zorder=5)
    ax.scatter([27, 43], [-0.86, -0.86], s=24, color=PANEL, edgecolor="#f8fbff", linewidth=1.0, zorder=6)
    ax.text(135.5, -0.86, "Avg power / temp", color="#c7d0d9", fontsize=10.5, ha="left", va="center")

    fig.text(
        0.065,
        0.91,
        "RTX 5090 long-context throughput: Qwopus Q5 stays usable to 256k",
        ha="left",
        va="center",
        color=TEXT,
        fontsize=27,
        fontweight="bold",
    )
    fig.text(
        0.065,
        0.858,
        "Qwopus3.6-27B-Coder-MTP Q5_K_M - llama.cpp b9761 - ctx=256k - MTP n=2 - 1024 generated tokens",
        ha="left",
        va="center",
        color="#cad5de",
        fontsize=13.5,
    )
    fig.text(
        0.065,
        0.796,
        "Higher is better",
        ha="left",
        va="center",
        color=BACKGROUND,
        fontsize=11,
        fontweight="bold",
        bbox={
            "boxstyle": "round,pad=0.32,rounding_size=0.18",
            "facecolor": "#f1c84b",
            "edgecolor": "#f1c84b",
        },
    )
    fig.text(
        0.205,
        0.796,
        "Bars show average completion throughput. Rails show measured min/max across runs.",
        ha="left",
        va="center",
        color=MUTED,
        fontsize=11.5,
    )
    fig.text(
        0.065,
        0.093,
        "Source: results/rtx-5090 CSVs, 2026-06-22. Prompt style: BookContext. "
        "Run 1 includes prefill overhead except the separately warmed 256k run.",
        ha="left",
        va="center",
        color="#89939e",
        fontsize=10.5,
    )
    fig.text(
        0.94,
        0.093,
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
    return png_path, svg_path


if __name__ == "__main__":
    png, svg = draw_chart()
    print(png)
    print(svg)
