from __future__ import annotations

import csv
import html
import math
import re
from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESULTS_CSV = (
    ROOT
    / "results"
    / "rtx-5090"
    / "qwen36-27b-nvfp4-gguf-mtp-comparison-20260703.csv"
)
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_SVG_PATH = OUTPUT_DIR / "qwen36-27b-nvfp4-mtp-vs-no-mtp.svg"
OUTPUT_PNG_PATH = OUTPUT_DIR / "qwen36-27b-nvfp4-mtp-vs-no-mtp.png"


@dataclass(frozen=True)
class Row:
    mode: str
    context_label: str
    target_prompt_tokens: int
    prompt_tokens: int
    completion_tokens: int
    context_slot: int
    decode_tps: float
    prefill_seconds: float
    wall_tps: float
    draft_acceptance: float | None
    memory_after_mib: int
    temperature_c: int


MODE_COLORS = {
    "No MTP": "#8fa3ba",
    "draft-mtp n=2": "#ff4d4d",
}


def fmt_one(value: float) -> str:
    return str(Decimal(str(value)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


def fmt_gib(mib: int) -> str:
    return fmt_one(mib / 1024)


def read_rows() -> list[Row]:
    rows: list[Row] = []
    with RESULTS_CSV.open(newline="", encoding="utf-8-sig") as handle:
        for raw in csv.DictReader(handle):
            draft = raw["draft_acceptance"]
            rows.append(
                Row(
                    mode=raw["mode"],
                    context_label=raw["context_label"],
                    target_prompt_tokens=int(raw["target_prompt_tokens"]),
                    prompt_tokens=int(raw["prompt_tokens"]),
                    completion_tokens=int(raw["completion_tokens"]),
                    context_slot=int(raw["context_slot"]),
                    decode_tps=float(raw["decode_tps"]),
                    prefill_seconds=float(raw["prefill_seconds"]),
                    wall_tps=float(raw["wall_tps"]),
                    draft_acceptance=float(draft) if draft else None,
                    memory_after_mib=int(raw["memory_after_mib"]),
                    temperature_c=int(raw["temperature_c"]),
                )
            )
    return rows


def grouped(rows: list[Row]) -> list[tuple[str, list[Row]]]:
    result = []
    for label in ("10K prompt", "200K prompt"):
        group_rows = [row for row in rows if row.context_label == label]
        if group_rows:
            result.append((label, sorted(group_rows, key=lambda row: row.mode != "No MTP")))
    return result


def speedup(rows: list[Row]) -> float | None:
    base = next((row.decode_tps for row in rows if row.mode == "No MTP"), None)
    mtp = next((row.decode_tps for row in rows if row.mode == "draft-mtp n=2"), None)
    if base is None or mtp is None or base == 0:
        return None
    return (mtp / base) - 1


def detail(row: Row) -> str:
    parts = [
        f"{row.prompt_tokens:,} prompt tokens",
        f"prefill {fmt_one(row.prefill_seconds)}s",
        f"wall {fmt_one(row.wall_tps)} tok/s",
        f"{fmt_gib(row.memory_after_mib)} GiB",
    ]
    if row.draft_acceptance is not None:
        parts.append(f"accept {row.draft_acceptance * 100:.1f}%")
    return "; ".join(parts)


def svg_text(x: float, y: float, text: str, **attrs: str) -> str:
    pairs = []
    for key, value in attrs.items():
        attr_name = key[:-1] if key.endswith("_") else key.replace("_", "-")
        pairs.append(f'{attr_name}="{html.escape(str(value))}"')
    attr = " ".join(pairs)
    return f'<text x="{x:.1f}" y="{y:.1f}" {attr}>{html.escape(text)}</text>'


def render_svg(rows: list[Row]) -> Path:
    groups = grouped(rows)
    width = 1900
    height = 760
    left = 760
    right = 90
    top = 245
    row_h = 72
    group_gap = 200
    bar_h = 34
    plot_w = width - left - right
    panel_bottom = height - 118
    scale_max = max(25, math.ceil(max(row.decode_tps for row in rows) / 25) * 25)

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        "<style>",
        "text{font-family:Segoe UI,Arial,sans-serif;letter-spacing:0}",
        ".title{fill:#f3f5f7;font-size:42px;font-weight:800}",
        ".subtitle{fill:#b8c2cc;font-size:20px}",
        ".note{fill:#9aa6b2;font-size:15px}",
        ".group{fill:#f3f5f7;font-size:24px;font-weight:800}",
        ".detail{fill:#8f9ba8;font-size:14px}",
        ".mode{fill:#e8edf2;font-size:18px;font-weight:750}",
        ".value{fill:#f3f5f7;font-size:22px;font-weight:800}",
        ".axis{fill:#8f9ba8;font-size:15px}",
        ".speedup{fill:#ffb86b;font-size:18px;font-weight:800}",
        "</style>",
        f'<rect width="{width}" height="{height}" fill="#101318"/>',
        f'<rect x="{left - 28}" y="{top - 58}" width="{plot_w + 56}" height="{panel_bottom - top + 92}" rx="10" fill="#171d24"/>',
    ]

    parts.append(svg_text(70, 76, "Qwen3.6 27B NVFP4 GGUF: MTP vs No MTP", class_="title"))
    parts.append(svg_text(70, 118, "RTX 5090, llama.cpp b9851, native Windows GGUF, ctx=200k, no-thinking, q4 KV.", class_="subtitle"))
    parts.append(svg_text(70, 152, "Bars show server-side llama.cpp decode tok/s. Row details include prompt prefill, full request wall-rate, VRAM, and draft acceptance.", class_="note"))
    parts.append(svg_text(70, 178, "Same BookContext 10k and 200k prompts with 1024 generated tokens.", class_="note"))

    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        parts.append(f'<line x1="{x:.1f}" y1="{top - 34}" x2="{x:.1f}" y2="{panel_bottom}" stroke="#2d3540" stroke-width="1"/>')
        parts.append(svg_text(x, panel_bottom + 28, str(tick), class_="axis", text_anchor="middle"))

    y = top
    for group_label, group_rows in groups:
        parts.append(svg_text(70, y - 20, group_label, class_="group"))
        pct = speedup(group_rows)
        if pct is not None:
            parts.append(svg_text(70, y + 10, f"draft-mtp n=2 {pct:+.1%} decode", class_="speedup"))
        for index, row in enumerate(group_rows):
            row_y = y + 46 + index * row_h
            bar_w = (row.decode_tps / scale_max) * plot_w
            color = MODE_COLORS.get(row.mode, "#9aa6b2")
            parts.append(svg_text(left - 34, row_y - 5, row.mode, class_="mode", text_anchor="end"))
            parts.append(svg_text(left - 34, row_y + 18, detail(row), class_="detail", text_anchor="end"))
            parts.append(f'<rect x="{left}" y="{row_y - 27}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="{color}" opacity="0.96"/>')
            parts.append(f'<rect x="{left}" y="{row_y - 27}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="none" stroke="#f5fff9" stroke-opacity="0.44"/>')
            parts.append(svg_text(left + bar_w + 14, row_y - 2, fmt_one(row.decode_tps), class_="value"))
            parts.append(svg_text(left + bar_w + 78, row_y - 2, "tok/s", class_="axis"))
        y += group_gap

    parts.append(svg_text(70, height - 52, "Source: results/rtx-5090/qwen36-27b-nvfp4-gguf-mtp-comparison-20260703.csv", class_="note"))
    parts.append(svg_text(width - 70, height - 52, "neko-legends/nvidia-local-llm-profiles", class_="note", text_anchor="end"))
    parts.append("</svg>")

    svg = "\n".join(parts) + "\n"
    svg = re.sub(r"[ \t]+\n", "\n", svg)
    OUTPUT_SVG_PATH.write_text(svg, encoding="utf-8")
    return OUTPUT_SVG_PATH


def render_png(rows: list[Row]) -> Path:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError as exc:
        raise SystemExit("Pillow is required to render the PNG chart.") from exc

    groups = grouped(rows)
    width = 1900
    height = 760
    left = 760
    right = 90
    top = 245
    row_h = 72
    group_gap = 200
    bar_h = 34
    plot_w = width - left - right
    panel_bottom = height - 118
    scale_max = max(25, math.ceil(max(row.decode_tps for row in rows) / 25) * 25)

    image = Image.new("RGB", (width, height), "#101318")
    draw = ImageDraw.Draw(image)
    font_dir = Path("C:/Windows/Fonts")

    def font(name: str, size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
        path = font_dir / name
        if path.exists():
            return ImageFont.truetype(str(path), size)
        return ImageFont.load_default()

    title_font = font("segoeuib.ttf", 42)
    subtitle_font = font("segoeui.ttf", 20)
    note_font = font("segoeui.ttf", 15)
    group_font = font("segoeuib.ttf", 24)
    detail_font = font("segoeui.ttf", 14)
    mode_font = font("segoeuib.ttf", 18)
    value_font = font("segoeuib.ttf", 22)
    axis_font = font("segoeui.ttf", 15)
    speedup_font = font("segoeuib.ttf", 18)

    draw.rounded_rectangle([left - 28, top - 58, left - 28 + plot_w + 56, panel_bottom + 34], radius=10, fill="#171d24")
    draw.text((70, 42), "Qwen3.6 27B NVFP4 GGUF: MTP vs No MTP", fill="#f3f5f7", font=title_font)
    draw.text((70, 100), "RTX 5090, llama.cpp b9851, native Windows GGUF, ctx=200k, no-thinking, q4 KV.", fill="#b8c2cc", font=subtitle_font)
    draw.text((70, 138), "Bars show server-side llama.cpp decode tok/s. Row details include prompt prefill, full request wall-rate, VRAM, and draft acceptance.", fill="#9aa6b2", font=note_font)
    draw.text((70, 166), "Same BookContext 10k and 200k prompts with 1024 generated tokens.", fill="#9aa6b2", font=note_font)

    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        draw.line([(x, top - 34), (x, panel_bottom)], fill="#2d3540", width=1)
        text = str(tick)
        bbox = draw.textbbox((0, 0), text, font=axis_font)
        draw.text((x - (bbox[2] - bbox[0]) / 2, panel_bottom + 16), text, fill="#8f9ba8", font=axis_font)

    y = top
    for group_label, group_rows in groups:
        draw.text((70, y - 50), group_label, fill="#f3f5f7", font=group_font)
        pct = speedup(group_rows)
        if pct is not None:
            draw.text((70, y - 20), f"draft-mtp n=2 {pct:+.1%} decode", fill="#ffb86b", font=speedup_font)
        for index, row in enumerate(group_rows):
            row_y = y + 19 + index * row_h
            bar_w = (row.decode_tps / scale_max) * plot_w
            color = MODE_COLORS.get(row.mode, "#9aa6b2")
            mode_bbox = draw.textbbox((0, 0), row.mode, font=mode_font)
            draw.text((left - 34 - (mode_bbox[2] - mode_bbox[0]), row_y - 24), row.mode, fill="#e8edf2", font=mode_font)
            row_detail = detail(row)
            detail_bbox = draw.textbbox((0, 0), row_detail, font=detail_font)
            draw.text((left - 34 - (detail_bbox[2] - detail_bbox[0]), row_y), row_detail, fill="#8f9ba8", font=detail_font)
            draw.rounded_rectangle([left, row_y - 27, left + bar_w, row_y - 27 + bar_h], radius=5, fill=color, outline="#d9fff8", width=1)
            value = fmt_one(row.decode_tps)
            draw.text((left + bar_w + 14, row_y - 27), value, fill="#f3f5f7", font=value_font)
            draw.text((left + bar_w + 78, row_y - 22), "tok/s", fill="#8f9ba8", font=axis_font)
        y += group_gap

    draw.text((70, height - 64), "Source: results/rtx-5090/qwen36-27b-nvfp4-gguf-mtp-comparison-20260703.csv", fill="#9aa6b2", font=note_font)
    repo = "neko-legends/nvidia-local-llm-profiles"
    bbox = draw.textbbox((0, 0), repo, font=note_font)
    draw.text((width - 70 - (bbox[2] - bbox[0]), height - 64), repo, fill="#9aa6b2", font=note_font)

    image.save(OUTPUT_PNG_PATH)
    return OUTPUT_PNG_PATH


def render() -> tuple[Path, Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = read_rows()
    if not rows:
        raise SystemExit("No Qwen27 MTP comparison rows found.")
    return render_svg(rows), render_png(rows)


if __name__ == "__main__":
    for path in render():
        print(path)
