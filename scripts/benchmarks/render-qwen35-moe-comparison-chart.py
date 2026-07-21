from __future__ import annotations

import csv
import html
import math
import re
from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = ROOT / "results" / "rtx-5090"
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_SVG_PATH = OUTPUT_DIR / "rtx-5090-qwen35-moe-vs-qwopus.svg"
OUTPUT_PNG_PATH = OUTPUT_DIR / "rtx-5090-qwen35-moe-vs-qwopus.png"
TIMING_CSV = RESULTS_DIR / "generation-timing-breakdowns-20260624.csv"
CHART_TITLE = "RTX 5090 Local GGUF Long-Context Comparison"
CHART_SUBTITLE = "Bars are generation/decode speed only; prompt prefill seconds are shown separately."
CHART_NOTE = "GGUF endpoints only. Updated July 21, 2026; vLLM and UI-observed rows are intentionally excluded."
CHART_FOOTER = "BookContext except labeled Laguna DFlash CodeContext rows; up to 1024 generated tokens, temperature 0."


@dataclass(frozen=True)
class ModelSpec:
    model: str
    file: str
    label: str
    color: str
    highlight: bool = False
    prompt_mode: str | None = None


MODEL_SPECS = [
    ModelSpec(
        "poolside/Laguna-XS-2.1-GGUF",
        "Laguna-XS-2.1-Q4_K_M.gguf",
        "Poolside Laguna XS 2.1 Q4_K_M (base)",
        "#ff5aa7",
        prompt_mode="OpenAI-compatible endpoint; no draft model",
    ),
    ModelSpec(
        "poolside/Laguna-XS-2.1-GGUF + Lucebox/Laguna-XS-2.1-DFlash-GGUF",
        "Laguna-XS-2.1-Q4_K_M.gguf + laguna-xs21-dflash-q4.gguf",
        "Laguna XS 2.1 + DFlash/KVFlash (CodeContext)",
        "#5dd6ff",
        prompt_mode="CodeContext; DFlash speculative drafter",
    ),
    ModelSpec(
        "deepreinforce-ai/Ornith-1.0-35B-GGUF",
        "ornith-1.0-35b-Q4_K_M.gguf",
        "Ornith 1.0 35B Q4_K_M",
        "#7edc72",
    ),
    ModelSpec(
        "Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF",
        "Qwopus3.6-35B-A3B-Coder-MTP-Q4_K_M.gguf",
        "Qwopus3.6 35B A3B Coder Q4_K_M",
        "#f2b846",
    ),
    ModelSpec(
        "Jackrong/Qwopus3.6-35B-A3B-Coder-MTP-GGUF",
        "Qwopus3.6-35B-A3B-Coder-MTP-Q5_K_M.gguf",
        "Qwopus3.6 35B A3B Coder Q5_K_M",
        "#45d6c9",
    ),
    ModelSpec(
        "AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4",
        "ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf",
        "AEON Ornith Uncensored NVFP4 MTP",
        "#82d56f",
    ),
    ModelSpec(
        "AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4",
        "aeon-ornith-1.0-35b-nvfp4.gguf",
        "AEON Ornith NVFP4 base GGUF",
        "#54c7ff",
    ),
    ModelSpec(
        "unsloth/Qwen3.6-35B-A3B-MTP-GGUF",
        "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf",
        "Unsloth Qwen3.6 35B UD-Q4_K_XL",
        "#9d82ff",
    ),
    ModelSpec(
        "nvidia/Qwen3.6-35B-A3B-NVFP4",
        "qwen3.6-35b-a3b-nvfp4-mtp.gguf",
        "neko-legends/Qwen3.6 35B NVFP4 MTP GGUF",
        "#b6f26a",
        True,
    ),
    ModelSpec(
        "unsloth/Qwen3.6-35B-A3B-NVFP4",
        "qwen3.6-35b-a3b-unsloth-nvfp4-mtp-gguf.gguf",
        "Unsloth Qwen3.6 35B A3B NVFP4 MTP",
        "#e7b84b",
    ),
    ModelSpec(
        "unsloth/Qwen3.6-35B-A3B-NVFP4-Fast",
        "qwen3.6-35b-a3b-unsloth-nvfp4-fast-mtp-gguf.gguf",
        "Unsloth Qwen3.6 35B NVFP4 Fast MTP",
        "#ff8a4c",
    ),
    ModelSpec(
        "nvidia/Qwen3.6-27B-NVFP4",
        "qwen3.6-27b-nvfp4-mtp-gguf.gguf",
        "NVIDIA Qwen3.6 27B NVFP4 MTP",
        "#8fa3ba",
    ),
    ModelSpec(
        "unsloth/Qwen3.6-27B-NVFP4",
        "qwen3.6-27b-unsloth-nvfp4-mtp-gguf.gguf",
        "Unsloth Qwen3.6 27B NVFP4 MTP",
        "#e7b84b",
    ),
    ModelSpec(
        "Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF",
        "Qwopus3.6-27B-Coder-MTP-Q5_K_M.gguf",
        "Qwopus3.6 27B Coder Q5_K_M",
        "#60a5ff",
    ),
    ModelSpec(
        "Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF",
        "Qwopus3.6-27B-Coder-MTP-Q4_K_M.gguf",
        "Qwopus3.6 27B Coder Q4_K_M",
        "#f2b846",
    ),
]


def fnum(value: str | None) -> float:
    return float(value) if value not in ("", None) else math.nan


def fmt_one(value: float) -> str:
    return str(Decimal(str(value)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


def fmt_seconds(value: float, approximate: bool = False) -> str:
    prefix = "~" if approximate else ""
    return f"{prefix}{fmt_one(value)}s"


def context_group(tokens: int) -> str:
    return "10K prompt" if tokens < 50_000 else "200K prompt"


def read_timing_rows() -> list[dict[str, str]]:
    with TIMING_CSV.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def latest_rows_by_spec() -> list[dict[str, object]]:
    timing_rows = read_timing_rows()
    chart_rows: list[dict[str, object]] = []

    for spec in MODEL_SPECS:
        matching = [
            row
            for row in timing_rows
            if row["model"] == spec.model
            and row["file"] == spec.file
            and (spec.prompt_mode is None or row["prompt_mode"] == spec.prompt_mode)
        ]
        for group in ("10K prompt", "200K prompt"):
            group_rows = [
                row for row in matching if context_group(int(row["context_tokens"])) == group
            ]
            if not group_rows:
                continue
            row = sorted(group_rows, key=lambda item: item["timestamp"])[-1]
            source = row.get("timing_source", "")
            approximate = "estimate" in source.lower()
            prompt_eval = fnum(row.get("prompt_eval_seconds"))
            detail = f'{int(row["context_tokens"]):,} prompt tokens'
            if not math.isnan(prompt_eval):
                detail += f"; prefill {fmt_seconds(prompt_eval, approximate)}"
            if approximate:
                detail += "; estimated split"

            chart_rows.append(
                {
                    "group": group,
                    "label": spec.label,
                    "detail": detail,
                    "tps": fnum(row["generation_tps"]),
                    "color": spec.color,
                    "file": spec.file,
                    "highlight": spec.highlight,
                }
            )

    chart_rows.sort(key=lambda row: (row["group"] != "10K prompt", -float(row["tps"])))
    return chart_rows


def svg_text(x: float, y: float, text: str, **attrs: str) -> str:
    pairs = []
    for key, value in attrs.items():
        attr_name = key[:-1] if key.endswith("_") else key.replace("_", "-")
        pairs.append(f'{attr_name}="{html.escape(str(value))}"')
    attr = " ".join(pairs)
    return f'<text x="{x:.1f}" y="{y:.1f}" {attr}>{html.escape(text)}</text>'


def layout(rows: list[dict[str, object]]) -> tuple[list[int], int]:
    row_gap = 64
    group_gap = 76
    y_positions: list[int] = []
    y = 250
    current_group = ""
    for row in rows:
        if current_group and row["group"] != current_group:
            y += group_gap
        current_group = str(row["group"])
        y_positions.append(y)
        y += row_gap
    return y_positions, y + 150


def render_svg(rows: list[dict[str, object]], scale_max: int) -> Path:
    width = 1900
    y_positions, height = layout(rows)
    left = 700
    right = 120
    plot_w = width - left - right
    bar_h = 34
    panel_top = 188
    panel_bottom = height - 112

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        "<style>",
        "text{font-family:Segoe UI,Arial,sans-serif;letter-spacing:0}",
        ".title{fill:#edf3f7;font-size:42px;font-weight:750}",
        ".subtitle{fill:#b5bec8;font-size:20px}",
        ".group{fill:#edf3f7;font-size:24px;font-weight:750}",
        ".label{fill:#edf3f7;font-size:18px;font-weight:700}",
        ".label-highlight{fill:#ff4d4d;font-size:20px;font-weight:900}",
        ".detail{fill:#8e99a6;font-size:14px}",
        ".value{fill:#edf3f7;font-size:21px;font-weight:750}",
        ".small{fill:#9aa5b1;font-size:16px}",
        ".axis{fill:#9aa5b1;font-size:15px}",
        "</style>",
        f'<rect width="{width}" height="{height}" fill="#111418"/>',
        f'<rect x="{left - 28}" y="{panel_top}" width="{plot_w + 56}" height="{panel_bottom - panel_top}" rx="10" fill="#181e25"/>',
    ]

    parts.append(svg_text(72, 76, CHART_TITLE, class_="title"))
    parts.append(svg_text(72, 118, CHART_SUBTITLE, class_="subtitle"))
    parts.append(svg_text(72, 150, CHART_NOTE, class_="small"))

    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        parts.append(f'<line x1="{x:.1f}" y1="{panel_top + 24}" x2="{x:.1f}" y2="{panel_bottom - 34}" stroke="#2f3742" stroke-width="1"/>')
        parts.append(svg_text(x, panel_bottom - 10, str(tick), class_="axis", text_anchor="middle"))

    group_seen: set[str] = set()
    for row, ypos in zip(rows, y_positions):
        group = str(row["group"])
        if group not in group_seen:
            group_seen.add(group)
            parts.append(svg_text(72, ypos - 42, group, class_="group"))

        value = float(row["tps"])
        bar_w = (value / scale_max) * plot_w
        label_class = "label-highlight" if row.get("highlight") else "label"
        parts.append(svg_text(left - 30, ypos - 5, str(row["label"]), class_=label_class, text_anchor="end"))
        parts.append(svg_text(left - 30, ypos + 17, str(row["detail"]), class_="detail", text_anchor="end"))
        parts.append(f'<rect x="{left}" y="{ypos - 26}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="{row["color"]}" opacity="0.95"/>')
        parts.append(f'<rect x="{left}" y="{ypos - 26}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="none" stroke="#d9fff8" stroke-opacity="0.50"/>')
        parts.append(svg_text(left + bar_w + 12, ypos - 1, fmt_one(value), class_="value"))
        parts.append(svg_text(left + bar_w + 72, ypos - 1, "tok/s", class_="small"))

    parts.append(svg_text(72, height - 50, CHART_FOOTER, class_="small"))
    parts.append(svg_text(width - 72, height - 50, "neko-legends/nvidia-local-llm-profiles", class_="small", text_anchor="end"))
    parts.append("</svg>")

    svg = "\n".join(parts) + "\n"
    svg = re.sub(r"[ \t]+\n", "\n", svg)
    OUTPUT_SVG_PATH.write_text(svg, encoding="utf-8")
    return OUTPUT_SVG_PATH


def render_png(rows: list[dict[str, object]], scale_max: int) -> Path:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError as exc:
        raise SystemExit("Pillow is required to render the PNG chart.") from exc

    width = 1900
    y_positions, height = layout(rows)
    left = 700
    right = 120
    plot_w = width - left - right
    bar_h = 34
    panel_top = 188
    panel_bottom = height - 112

    image = Image.new("RGB", (width, height), "#111418")
    draw = ImageDraw.Draw(image)
    font_dir = Path("C:/Windows/Fonts")

    def font(name: str, size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
        path = font_dir / name
        if path.exists():
            return ImageFont.truetype(str(path), size)
        return ImageFont.load_default()

    title_font = font("segoeuib.ttf", 42)
    subtitle_font = font("segoeui.ttf", 20)
    group_font = font("segoeuib.ttf", 24)
    label_font = font("segoeuib.ttf", 18)
    label_highlight_font = font("segoeuib.ttf", 20)
    detail_font = font("segoeui.ttf", 14)
    value_font = font("segoeuib.ttf", 21)
    small_font = font("segoeui.ttf", 16)

    draw.rounded_rectangle([left - 28, panel_top, left - 28 + plot_w + 56, panel_bottom], radius=10, fill="#181e25")
    draw.text((72, 42), CHART_TITLE, fill="#edf3f7", font=title_font)
    draw.text((72, 100), CHART_SUBTITLE, fill="#b5bec8", font=subtitle_font)
    draw.text((72, 138), CHART_NOTE, fill="#9aa5b1", font=small_font)

    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        draw.line([(x, panel_top + 24), (x, panel_bottom - 34)], fill="#2f3742", width=1)
        text = str(tick)
        bbox = draw.textbbox((0, 0), text, font=small_font)
        draw.text((x - (bbox[2] - bbox[0]) / 2, panel_bottom - 30), text, fill="#9aa5b1", font=small_font)

    group_seen: set[str] = set()
    for row, ypos in zip(rows, y_positions):
        group = str(row["group"])
        if group not in group_seen:
            group_seen.add(group)
            draw.text((72, ypos - 66), group, fill="#edf3f7", font=group_font)

        value = float(row["tps"])
        bar_w = (value / scale_max) * plot_w
        label = str(row["label"])
        detail = str(row["detail"])
        current_label_font = label_highlight_font if row.get("highlight") else label_font
        label_fill = "#ff4d4d" if row.get("highlight") else "#edf3f7"
        bbox = draw.textbbox((0, 0), label, font=current_label_font)
        draw.text((left - 30 - (bbox[2] - bbox[0]), ypos - 31), label, fill=label_fill, font=current_label_font)
        bbox = draw.textbbox((0, 0), detail, font=detail_font)
        draw.text((left - 30 - (bbox[2] - bbox[0]), ypos - 7), detail, fill="#8e99a6", font=detail_font)
        draw.rounded_rectangle([left, ypos - 26, left + bar_w, ypos - 26 + bar_h], radius=5, fill=str(row["color"]), outline="#d9fff8", width=1)
        draw.text((left + bar_w + 12, ypos - 25), fmt_one(value), fill="#edf3f7", font=value_font)
        draw.text((left + bar_w + 72, ypos - 20), "tok/s", fill="#9aa5b1", font=small_font)

    draw.text((72, height - 62), CHART_FOOTER, fill="#9aa5b1", font=small_font)
    repo = "neko-legends/nvidia-local-llm-profiles"
    bbox = draw.textbbox((0, 0), repo, font=small_font)
    draw.text((width - 72 - (bbox[2] - bbox[0]), height - 62), repo, fill="#9aa5b1", font=small_font)

    image.save(OUTPUT_PNG_PATH)
    return OUTPUT_PNG_PATH


def render() -> tuple[Path, Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = latest_rows_by_spec()
    if not rows:
        raise SystemExit("No native llama.cpp timing rows found.")
    max_value = max(float(row["tps"]) for row in rows)
    scale_max = max(25, math.ceil(max_value / 25) * 25)
    return render_svg(rows, scale_max), render_png(rows, scale_max)


if __name__ == "__main__":
    for path in render():
        print(path)
