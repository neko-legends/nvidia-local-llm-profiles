from __future__ import annotations

import csv
import html
import math
from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
RESULTS = ROOT / "results" / "rtx-5090" / "qwen36-unsloth-nvfp4-native-comparison-20260710.csv"
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_SVG = OUTPUT_DIR / "qwen36-unsloth-nvfp4-native-comparison.svg"
OUTPUT_PNG = OUTPUT_DIR / "qwen36-unsloth-nvfp4-native-comparison.png"

COLORS = {"NVIDIA": "#8fa3ba", "Unsloth": "#e7b84b"}
FAMILY_ORDER = ("27B", "35B A3B")
CONTEXT_ORDER = ("10K prompt", "200K prompt")


@dataclass(frozen=True)
class Row:
    family: str
    source: str
    repo: str
    context: str
    prompt_tokens: int
    tps: float
    memory_mib: int
    temp_c: int
    file_gib: float


def one(value: float) -> str:
    return str(Decimal(str(value)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


def read_rows() -> list[Row]:
    with RESULTS.open(newline="", encoding="utf-8-sig") as handle:
        return [
            Row(
                family=raw["family"],
                source=raw["source"],
                repo=raw["source_repo"],
                context=raw["context_label"],
                prompt_tokens=int(raw["prompt_tokens"]),
                tps=float(raw["decode_tps"]),
                memory_mib=int(raw["memory_after_mib"]),
                temp_c=int(raw["temperature_c"]),
                file_gib=float(raw["model_file_gib"]),
            )
            for raw in csv.DictReader(handle)
        ]


def groups(rows: list[Row]) -> list[tuple[str, str, list[Row]]]:
    return [
        (
            family,
            context,
            sorted(
                [row for row in rows if row.family == family and row.context == context],
                key=lambda row: 0 if row.source == "NVIDIA" else 1,
            ),
        )
        for family in FAMILY_ORDER
        for context in CONTEXT_ORDER
    ]


def text_svg(x: float, y: float, value: str, **attrs: object) -> str:
    rendered = " ".join(
        f'{key[:-1] if key.endswith("_") else key.replace("_", "-")}="{html.escape(str(attr))}"'
        for key, attr in attrs.items()
    )
    return f'<text x="{x:.1f}" y="{y:.1f}" {rendered}>{html.escape(value)}</text>'


def dimensions(rows: list[Row]) -> tuple[int, int, int, int, int]:
    return 2000, 1310, 800, 120, 240


def group_scale(rows: list[Row]) -> float:
    highest = max(row.tps for row in rows)
    step = 25 if highest > 30 else 5
    return max(step, math.ceil(highest / step) * step)


def render_svg(rows: list[Row]) -> None:
    width, height, left, right, group_h = dimensions(rows)
    plot_w = width - left - right
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        "<style>text{font-family:Segoe UI,Arial,sans-serif;letter-spacing:0}.title{fill:#f5f4ef;font-size:42px;font-weight:800}.subtitle{fill:#c9c6bd;font-size:20px}.note{fill:#aaa9a3;font-size:15px}.heading{fill:#f5f4ef;font-size:24px;font-weight:800}.label{fill:#efeee8;font-size:18px;font-weight:750}.detail{fill:#aaa9a3;font-size:14px}.value{fill:#f5f4ef;font-size:22px;font-weight:800}.axis{fill:#aaa9a3;font-size:14px}</style>",
        f'<rect width="{width}" height="{height}" fill="#121210"/>',
    ]
    parts.extend(
        [
            text_svg(70, 76, "Qwen3.6 NVFP4: NVIDIA vs Unsloth Native GGUF", class_="title"),
            text_svg(70, 118, "RTX 5090, Windows 11, llama.cpp b9851, ctx=200k, draft-mtp n=2, no-thinking, 1024 generated tokens.", class_="subtitle"),
            text_svg(70, 150, "Bars are llama.cpp decode-only generation throughput after prompt prefill. Each panel has its own scale.", class_="note"),
            text_svg(70, 178, "Unsloth mixed NVFP4/FP8 sources were converted with FP8 stored as Q8_0; FFN tensors remain native NVFP4.", class_="note"),
        ]
    )
    for index, (family, context, group_rows) in enumerate(groups(rows)):
        top = 240 + index * group_h
        scale = group_scale(group_rows)
        parts.append(f'<rect x="40" y="{top - 52:.1f}" width="1920" height="{group_h - 22:.1f}" rx="8" fill="#1b1b18"/>')
        parts.append(text_svg(70, top, f"{family} | {context} | {group_rows[0].prompt_tokens:,} actual prompt tokens", class_="heading"))
        for tick in range(0, int(scale) + 1, 25 if scale > 30 else 5):
            x = left + tick / scale * plot_w
            parts.append(f'<line x1="{x:.1f}" y1="{top + 20:.1f}" x2="{x:.1f}" y2="{top + 152:.1f}" stroke="#34342f" stroke-width="1"/>')
            parts.append(text_svg(x, top + 180, str(tick), class_="axis", text_anchor="middle"))
        for row_index, row in enumerate(group_rows):
            y = top + 64 + row_index * 70
            width_bar = row.tps / scale * plot_w
            parts.append(text_svg(left - 34, y - 4, row.source, class_="label", text_anchor="end"))
            parts.append(text_svg(left - 34, y + 18, f"{row.file_gib:.1f} GiB file | {row.memory_mib / 1024:.1f} GiB VRAM | {row.temp_c} C", class_="detail", text_anchor="end"))
            parts.append(f'<rect x="{left}" y="{y - 26:.1f}" width="{width_bar:.1f}" height="34" rx="4" fill="{COLORS[row.source]}"/>')
            parts.append(text_svg(left + width_bar + 14, y - 2, one(row.tps), class_="value"))
            parts.append(text_svg(left + width_bar + 85, y - 2, "tok/s", class_="axis"))
    parts.extend(
        [
            text_svg(70, height - 55, "Sources: fresh local benchmark CSVs dated 2026-07-10. Native Windows CUDA only; no Docker/vLLM rows in this comparison.", class_="note"),
            text_svg(width - 70, height - 55, "neko-legends/nvidia-local-llm-profiles", class_="note", text_anchor="end"),
            "</svg>",
        ]
    )
    OUTPUT_SVG.write_text("\n".join(parts) + "\n", encoding="utf-8")


def render_png(rows: list[Row]) -> None:
    width, height, left, right, group_h = dimensions(rows)
    plot_w = width - left - right
    image = Image.new("RGB", (width, height), "#121210")
    draw = ImageDraw.Draw(image)
    fonts = Path("C:/Windows/Fonts")

    def font(name: str, size: int) -> ImageFont.FreeTypeFont:
        return ImageFont.truetype(str(fonts / name), size)

    title = font("segoeuib.ttf", 42)
    subtitle = font("segoeui.ttf", 20)
    heading = font("segoeuib.ttf", 24)
    label = font("segoeuib.ttf", 18)
    detail = font("segoeui.ttf", 14)
    value = font("segoeuib.ttf", 22)
    axis = font("segoeui.ttf", 14)
    draw.text((70, 40), "Qwen3.6 NVFP4: NVIDIA vs Unsloth Native GGUF", fill="#f5f4ef", font=title)
    draw.text((70, 100), "RTX 5090, Windows 11, llama.cpp b9851, ctx=200k, draft-mtp n=2, no-thinking, 1024 generated tokens.", fill="#c9c6bd", font=subtitle)
    draw.text((70, 138), "Bars are llama.cpp decode-only generation throughput after prompt prefill. Each panel has its own scale.", fill="#aaa9a3", font=detail)
    draw.text((70, 164), "Unsloth mixed NVFP4/FP8 sources were converted with FP8 stored as Q8_0; FFN tensors remain native NVFP4.", fill="#aaa9a3", font=detail)
    for index, (family, context, group_rows) in enumerate(groups(rows)):
        top = 240 + index * group_h
        scale = group_scale(group_rows)
        draw.rounded_rectangle([40, top - 52, 1960, top + group_h - 74], radius=8, fill="#1b1b18")
        draw.text((70, top - 25), f"{family} | {context} | {group_rows[0].prompt_tokens:,} actual prompt tokens", fill="#f5f4ef", font=heading)
        for tick in range(0, int(scale) + 1, 25 if scale > 30 else 5):
            x = left + tick / scale * plot_w
            draw.line([(x, top + 20), (x, top + 152)], fill="#34342f", width=1)
            tick_label = str(tick)
            bbox = draw.textbbox((0, 0), tick_label, font=axis)
            draw.text((x - (bbox[2] - bbox[0]) / 2, top + 164), tick_label, fill="#aaa9a3", font=axis)
        for row_index, row in enumerate(group_rows):
            y = top + 64 + row_index * 70
            bar_width = row.tps / scale * plot_w
            name_bbox = draw.textbbox((0, 0), row.source, font=label)
            draw.text((left - 34 - (name_bbox[2] - name_bbox[0]), y - 25), row.source, fill="#efeee8", font=label)
            line = f"{row.file_gib:.1f} GiB file | {row.memory_mib / 1024:.1f} GiB VRAM | {row.temp_c} C"
            line_bbox = draw.textbbox((0, 0), line, font=detail)
            draw.text((left - 34 - (line_bbox[2] - line_bbox[0]), y), line, fill="#aaa9a3", font=detail)
            draw.rounded_rectangle([left, y - 26, left + bar_width, y + 8], radius=4, fill=COLORS[row.source])
            draw.text((left + bar_width + 14, y - 26), one(row.tps), fill="#f5f4ef", font=value)
            draw.text((left + bar_width + 84, y - 21), "tok/s", fill="#aaa9a3", font=axis)
    draw.text((70, height - 66), "Sources: fresh local benchmark CSVs dated 2026-07-10. Native Windows CUDA only; no Docker/vLLM rows in this comparison.", fill="#aaa9a3", font=detail)
    repo = "neko-legends/nvidia-local-llm-profiles"
    repo_box = draw.textbbox((0, 0), repo, font=detail)
    draw.text((width - 70 - (repo_box[2] - repo_box[0]), height - 66), repo, fill="#aaa9a3", font=detail)
    image.save(OUTPUT_PNG)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = read_rows()
    render_svg(rows)
    render_png(rows)
    print(OUTPUT_SVG)
    print(OUTPUT_PNG)


if __name__ == "__main__":
    main()
