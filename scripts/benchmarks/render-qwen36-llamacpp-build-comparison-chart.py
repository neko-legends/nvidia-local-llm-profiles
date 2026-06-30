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
    / "qwen36-35b-a3b-nvfp4-mtp-gguf-llamacpp-build-comparison-20260630.csv"
)
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_SVG_PATH = OUTPUT_DIR / "qwen36-llamacpp-b9761-vs-b9851.svg"
OUTPUT_PNG_PATH = OUTPUT_DIR / "qwen36-llamacpp-b9761-vs-b9851.png"


@dataclass(frozen=True)
class BuildRow:
    build: str
    commit: str
    prompt_label: str
    target_prompt_tokens: int
    prompt_tokens: int
    completion_tokens: int
    context_slot: int
    decode_tps: float
    prefill_tps: float
    draft_acceptance: float
    truncated: bool


BUILD_COLORS = {
    "b9761": "#8fa3ba",
    "b9851": "#ff4d4d",
}


def read_rows() -> list[BuildRow]:
    with RESULTS_CSV.open(newline="", encoding="utf-8-sig") as handle:
        rows = []
        for raw in csv.DictReader(handle):
            rows.append(
                BuildRow(
                    build=raw["build"],
                    commit=raw["commit"],
                    prompt_label=raw["prompt_label"],
                    target_prompt_tokens=int(raw["target_prompt_tokens"]),
                    prompt_tokens=int(raw["prompt_tokens"]),
                    completion_tokens=int(raw["completion_tokens"]),
                    context_slot=int(raw["context_slot"]),
                    decode_tps=float(raw["decode_tps"]),
                    prefill_tps=float(raw["prefill_tps"]),
                    draft_acceptance=float(raw["draft_acceptance"]),
                    truncated=raw["truncated"].lower() == "true",
                )
            )
    return rows


def fmt_one(value: float) -> str:
    return str(Decimal(str(value)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


def fmt_pct(value: float) -> str:
    return f"{value * 100:.1f}%"


def svg_text(x: float, y: float, text: str, **attrs: str) -> str:
    pairs = []
    for key, value in attrs.items():
        attr_name = key[:-1] if key.endswith("_") else key.replace("_", "-")
        pairs.append(f'{attr_name}="{html.escape(str(value))}"')
    attr = " ".join(pairs)
    return f'<text x="{x:.1f}" y="{y:.1f}" {attr}>{html.escape(text)}</text>'


def grouped(rows: list[BuildRow]) -> list[tuple[str, list[BuildRow]]]:
    order = ["10K prompt", "200K prompt", "300K target / 262K cap"]
    result = []
    for label in order:
        group_rows = [row for row in rows if row.prompt_label == label]
        if group_rows:
            result.append((label, sorted(group_rows, key=lambda row: row.build)))
    return result


def group_detail(rows: list[BuildRow]) -> str:
    first = rows[0]
    generated = f"{first.completion_tokens} generated"
    if first.truncated:
        generated += "; truncated"
    return f"{first.prompt_tokens:,} prompt tokens; {generated}; ctx slot {first.context_slot:,}"


def speedup(rows: list[BuildRow]) -> float | None:
    old = next((row.decode_tps for row in rows if row.build == "b9761"), None)
    new = next((row.decode_tps for row in rows if row.build == "b9851"), None)
    if old is None or new is None or old == 0:
        return None
    return (new / old) - 1


def render_svg(rows: list[BuildRow]) -> Path:
    groups = grouped(rows)
    width = 1800
    height = 860
    left = 460
    right = 220
    top = 240
    row_h = 38
    group_gap = 150
    bar_h = 28
    plot_w = width - left - right
    scale_max = max(25, math.ceil(max(row.decode_tps for row in rows) / 25) * 25)

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        "<style>",
        "text{font-family:Segoe UI,Arial,sans-serif;letter-spacing:0}",
        ".title{fill:#f3f5f7;font-size:42px;font-weight:800}",
        ".subtitle{fill:#b8c2cc;font-size:20px}",
        ".note{fill:#9aa6b2;font-size:15px}",
        ".group{fill:#f3f5f7;font-size:24px;font-weight:800}",
        ".detail{fill:#8f9ba8;font-size:15px}",
        ".build{fill:#e8edf2;font-size:18px;font-weight:750}",
        ".value{fill:#f3f5f7;font-size:22px;font-weight:800}",
        ".axis{fill:#8f9ba8;font-size:15px}",
        ".speedup{fill:#ffb86b;font-size:18px;font-weight:800}",
        "</style>",
        f'<rect width="{width}" height="{height}" fill="#101318"/>',
        f'<rect x="{left - 28}" y="{top - 54}" width="{plot_w + 56}" height="{height - top - 94}" rx="10" fill="#171d24"/>',
    ]

    parts.append(svg_text(70, 76, "llama.cpp Build Upgrade: b9761 -> b9851", class_="title"))
    parts.append(svg_text(70, 118, "NVIDIA Qwen3.6 35B A3B NVFP4 MTP GGUF on RTX 5090. Bars show llama.cpp decode tok/s only.", class_="subtitle"))
    parts.append(svg_text(70, 152, "Same GGUF, CUDA 13.3 Windows builds, draft-mtp n=2, no-thinking, q4 target/draft KV. No wall-rate numbers shown.", class_="note"))
    parts.append(svg_text(70, 178, "The 300K target reaches the model's 262K context cap and truncates after 183 generated tokens; treat it as a max-context edge check.", class_="note"))

    panel_bottom = height - 112
    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        parts.append(f'<line x1="{x:.1f}" y1="{top - 30}" x2="{x:.1f}" y2="{panel_bottom - 10}" stroke="#2d3540" stroke-width="1"/>')
        parts.append(svg_text(x, panel_bottom + 18, str(tick), class_="axis", text_anchor="middle"))

    y = top
    for group_label, group_rows in groups:
        parts.append(svg_text(70, y - 14, group_label, class_="group"))
        parts.append(svg_text(70, y + 12, group_detail(group_rows), class_="detail"))
        pct = speedup(group_rows)
        if pct is not None:
            parts.append(svg_text(70, y + 38, f"b9851 {pct:+.1%}", class_="speedup"))

        for index, row in enumerate(group_rows):
            bar_y = y + 54 + index * row_h
            bar_w = (row.decode_tps / scale_max) * plot_w
            color = BUILD_COLORS.get(row.build, "#9aa6b2")
            parts.append(svg_text(left - 34, bar_y + 20, f"{row.build} ({row.commit[:7]})", class_="build", text_anchor="end"))
            parts.append(f'<rect x="{left}" y="{bar_y}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="{color}" opacity="0.96"/>')
            parts.append(f'<rect x="{left}" y="{bar_y}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="none" stroke="#f5fff9" stroke-opacity="0.44"/>')
            parts.append(svg_text(left + bar_w + 14, bar_y + 21, fmt_one(row.decode_tps), class_="value"))
            parts.append(svg_text(left + bar_w + 76, bar_y + 21, "tok/s", class_="axis"))
        y += group_gap

    parts.append(svg_text(70, height - 48, "Source: server-side slot print_timing eval time. Prompt prefill and request wall time intentionally omitted.", class_="note"))
    parts.append(svg_text(width - 70, height - 48, "neko-legends/nvidia-local-llm-profiles", class_="note", text_anchor="end"))
    parts.append("</svg>")

    svg = "\n".join(parts) + "\n"
    svg = re.sub(r"[ \t]+\n", "\n", svg)
    OUTPUT_SVG_PATH.write_text(svg, encoding="utf-8")
    return OUTPUT_SVG_PATH


def render_png(rows: list[BuildRow]) -> Path:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError as exc:
        raise SystemExit("Pillow is required to render the PNG chart.") from exc

    groups = grouped(rows)
    width = 1800
    height = 860
    left = 460
    right = 220
    top = 240
    row_h = 38
    group_gap = 150
    bar_h = 28
    plot_w = width - left - right
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
    detail_font = font("segoeui.ttf", 15)
    build_font = font("segoeuib.ttf", 18)
    value_font = font("segoeuib.ttf", 22)
    axis_font = font("segoeui.ttf", 15)
    speedup_font = font("segoeuib.ttf", 18)

    panel_bottom = height - 112
    draw.rounded_rectangle([left - 28, top - 54, left - 28 + plot_w + 56, height - 146], radius=10, fill="#171d24")
    draw.text((70, 42), "llama.cpp Build Upgrade: b9761 -> b9851", fill="#f3f5f7", font=title_font)
    draw.text((70, 100), "NVIDIA Qwen3.6 35B A3B NVFP4 MTP GGUF on RTX 5090. Bars show llama.cpp decode tok/s only.", fill="#b8c2cc", font=subtitle_font)
    draw.text((70, 138), "Same GGUF, CUDA 13.3 Windows builds, draft-mtp n=2, no-thinking, q4 target/draft KV. No wall-rate numbers shown.", fill="#9aa6b2", font=note_font)
    draw.text((70, 166), "The 300K target reaches the model's 262K context cap and truncates after 183 generated tokens; treat it as a max-context edge check.", fill="#9aa6b2", font=note_font)

    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        draw.line([(x, top - 30), (x, panel_bottom - 10)], fill="#2d3540", width=1)
        label = str(tick)
        bbox = draw.textbbox((0, 0), label, font=axis_font)
        draw.text((x - (bbox[2] - bbox[0]) / 2, panel_bottom + 6), label, fill="#8f9ba8", font=axis_font)

    y = top
    for group_label, group_rows in groups:
        draw.text((70, y - 40), group_label, fill="#f3f5f7", font=group_font)
        draw.text((70, y - 6), group_detail(group_rows), fill="#8f9ba8", font=detail_font)
        pct = speedup(group_rows)
        if pct is not None:
            speed_text = f"b9851 {pct:+.1%}"
            draw.text((70, y + 20), speed_text, fill="#ffb86b", font=speedup_font)

        for index, row in enumerate(group_rows):
            bar_y = y + 38 + index * row_h
            bar_w = (row.decode_tps / scale_max) * plot_w
            color = BUILD_COLORS.get(row.build, "#9aa6b2")
            build_label = f"{row.build} ({row.commit[:7]})"
            bbox = draw.textbbox((0, 0), build_label, font=build_font)
            draw.text((left - 34 - (bbox[2] - bbox[0]), bar_y + 3), build_label, fill="#e8edf2", font=build_font)
            draw.rounded_rectangle([left, bar_y, left + bar_w, bar_y + bar_h], radius=5, fill=color, outline="#d9fff8", width=1)
            value = fmt_one(row.decode_tps)
            draw.text((left + bar_w + 14, bar_y - 1), value, fill="#f3f5f7", font=value_font)
            draw.text((left + bar_w + 76, bar_y + 4), "tok/s", fill="#8f9ba8", font=axis_font)
        y += group_gap

    draw.text((70, height - 60), "Source: server-side slot print_timing eval time. Prompt prefill and request wall time intentionally omitted.", fill="#9aa6b2", font=note_font)
    repo = "neko-legends/nvidia-local-llm-profiles"
    bbox = draw.textbbox((0, 0), repo, font=note_font)
    draw.text((width - 70 - (bbox[2] - bbox[0]), height - 60), repo, fill="#9aa6b2", font=note_font)

    image.save(OUTPUT_PNG_PATH)
    return OUTPUT_PNG_PATH


def render() -> tuple[Path, Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = read_rows()
    if not rows:
        raise SystemExit("No build comparison rows found.")
    return render_svg(rows), render_png(rows)


if __name__ == "__main__":
    for path in render():
        print(path)
