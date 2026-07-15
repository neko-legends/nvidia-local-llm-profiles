from __future__ import annotations

import csv
import html
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
DATA_PATH = ROOT / "results" / "rtx-5090" / "qwen36-27b-dflash-tuning-20260714.csv"
PNG_PATH = ROOT / "assets" / "images" / "qwen36-27b-dflash-windows-before-after-20260714.png"
SVG_PATH = ROOT / "assets" / "images" / "qwen36-27b-dflash-windows-before-after-20260714.svg"

WIDTH = 1800
HEIGHT = 1840
BG = "#101317"
PANEL = "#171d24"
GRID = "#303944"
TEXT = "#edf3f7"
MUTED = "#9aa6b2"
BEFORE = "#ff5a5f"
AFTER = "#49d6c8"
REFERENCE = "#f2bc4b"
INTERMEDIATE = "#6d9ff2"


def load_rows() -> list[dict[str, str]]:
    with DATA_PATH.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "segoeuib.ttf" if bold else "segoeui.ttf"
    return ImageFont.truetype(str(Path("C:/Windows/Fonts") / name), size)


def wrap(value: str, width: int) -> list[str]:
    return textwrap.wrap(value, width=width, break_long_words=False)


def esc(value: object) -> str:
    return html.escape(str(value))


def render_png(rows: list[dict[str, str]]) -> None:
    image = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(image)
    title = font(48, True)
    subtitle = font(23)
    section = font(30, True)
    label = font(22, True)
    body = font(19)
    detail = font(16)
    value_font = font(28, True)
    huge = font(58, True)

    draw.text((70, 48), "DFlash on Windows: 2.56x Faster After the Runtime Fixes", fill=TEXT, font=title)
    draw.text((70, 112), "RTX 5090, native llama.cpp, July 14 2026. Decode speed excludes prompt prefill.", fill=MUTED, font=subtitle)

    headline = [row for row in rows if row["section"] == "headline"]
    before, after = headline
    improvement = float(after["decode_tps"]) / float(before["decode_tps"])
    gain = (improvement - 1.0) * 100.0

    draw.rounded_rectangle((60, 170, 1740, 500), radius=8, fill=PANEL)
    draw.text((90, 195), "Comparable 10K BookContext before / after", fill=TEXT, font=section)
    draw.text((90, 238), "Same 8,907-token prompt, 1,024 generated tokens, temperature 0, ctx=200000", fill=MUTED, font=body)

    left = 480
    plot_width = 980
    scale = 70.0
    for tick in (0, 10, 20, 30, 40, 50, 60, 70):
        x = left + plot_width * tick / scale
        draw.line((x, 286, x, 452), fill=GRID, width=1)
        draw.text((x - 10, 456), str(tick), fill=MUTED, font=detail)

    for index, row in enumerate(headline):
        y = 315 + index * 82
        color = BEFORE if index == 0 else AFTER
        draw.text((90, y - 4), row["stage"], fill=color, font=label)
        width = plot_width * float(row["decode_tps"]) / scale
        draw.rounded_rectangle((left, y, left + width, y + 38), radius=5, fill=color)
        draw.text((left + width + 14, y - 2), f'{float(row["decode_tps"]):.2f} tok/s', fill=TEXT, font=value_font)

    draw.text((1500, 292), f"{improvement:.2f}x", fill=AFTER, font=huge)
    draw.text((1510, 360), f"+{gain:.0f}%", fill=TEXT, font=value_font)
    draw.text((1498, 402), "decode throughput", fill=MUTED, font=detail)

    draw.text((70, 550), "How the 1K tuning progressed", fill=TEXT, font=section)
    draw.text((70, 594), "All bars below use the same 1,174-token prose prompt and 1,024 generated tokens.", fill=MUTED, font=body)
    draw.rounded_rectangle((60, 635, 1740, 1038), radius=8, fill=PANEL)

    tuning = [row for row in rows if row["section"] == "tuning"]
    left = 610
    plot_width = 980
    scale = 75.0
    for tick in (0, 15, 30, 45, 60, 75):
        x = left + plot_width * tick / scale
        draw.line((x, 680, x, 982), fill=GRID, width=1)
        draw.text((x - 10, 990), str(tick), fill=MUTED, font=detail)

    for index, row in enumerate(tuning):
        y = 700 + index * 62
        if index == 0:
            color = BEFORE
        elif row["stage"] == "Target-only reference":
            color = REFERENCE
        elif index == len(tuning) - 2:
            color = AFTER
        else:
            color = INTERMEDIATE
        draw.text((90, y - 1), row["stage"], fill=TEXT, font=label)
        width = plot_width * float(row["decode_tps"]) / scale
        draw.rounded_rectangle((left, y, left + width, y + 30), radius=4, fill=color)
        draw.text((left + width + 12, y - 4), f'{float(row["decode_tps"]):.2f}', fill=TEXT, font=label)

    control = next(row for row in rows if row["section"] == "control")
    draw.rounded_rectangle((60, 1085, 1740, 1255), radius=8, fill="#15252a", outline=AFTER, width=2)
    draw.text((90, 1110), "Separate coding control", fill=AFTER, font=section)
    draw.text((90, 1155), "Short Python BST prompt", fill=TEXT, font=label)
    draw.text((440, 1120), f'{float(control["decode_tps"]):.2f} tok/s', fill=AFTER, font=huge)
    draw.text((860, 1135), "73.74% acceptance | mean accepted length 11.74", fill=TEXT, font=body)
    draw.text((860, 1170), "Not comparable to the long-context bars; it shows DFlash upside when predictions match.", fill=MUTED, font=detail)

    draw.text((70, 1310), "What changed", fill=TEXT, font=section)
    changes = [
        ("1", "Correct device placement", "Pinned target and draft to CUDA0; verified 65/65 target and 6/6 draft layers on the RTX 5090."),
        ("2", "Acceptance feedback fix", "Sent verification results to the per-slot DFlash state so adaptive logic receives real acceptance data."),
        ("3", "GPU-only adaptive bypass", "After four cycles with mean accepted length below 3, stop speculative work for that request."),
        ("4", "Hidden-capture fast gate", "Stop unused target hidden-state GPU-to-host copies after bypass; re-enable capture before the next request."),
        ("5", "Fail-fast placement check", "Abort before benchmarking if either model is partially offloaded or the draft lands on CUDA1."),
    ]
    y = 1360
    for number, heading, explanation in changes:
        draw.rounded_rectangle((70, y, 116, y + 46), radius=5, fill=AFTER)
        bbox = draw.textbbox((0, 0), number, font=label)
        draw.text((93 - (bbox[2] - bbox[0]) / 2, y + 7), number, fill=BG, font=label)
        draw.text((140, y), heading, fill=TEXT, font=label)
        draw.text((140, y + 29), explanation, fill=MUTED, font=detail)
        y += 84

    draw.text((70, 1790), "Before used draft ngl=1 and was CPU-heavy. After remains GPU-only; low-acceptance requests bypass DFlash, not CUDA.", fill=MUTED, font=detail)
    draw.text((1730, 1790), "neko-legends/nvidia-local-llm-profiles", fill=MUTED, font=detail, anchor="ra")
    PNG_PATH.parent.mkdir(parents=True, exist_ok=True)
    image.save(PNG_PATH)


def svg_text(x: int, y: int, value: str, css_class: str, anchor: str = "start") -> str:
    return f'<text x="{x}" y="{y}" class="{css_class}" text-anchor="{anchor}">{esc(value)}</text>'


def render_svg(rows: list[dict[str, str]]) -> None:
    headline = [row for row in rows if row["section"] == "headline"]
    before, after = headline
    improvement = float(after["decode_tps"]) / float(before["decode_tps"])
    gain = (improvement - 1.0) * 100.0
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">',
        "<style>",
        "text{font-family:Segoe UI,Arial,sans-serif;letter-spacing:0}",
        ".title{fill:#edf3f7;font-size:48px;font-weight:750}.subtitle{fill:#9aa6b2;font-size:23px}",
        ".section{fill:#edf3f7;font-size:30px;font-weight:750}.label{fill:#edf3f7;font-size:22px;font-weight:700}",
        ".body{fill:#edf3f7;font-size:19px}.detail{fill:#9aa6b2;font-size:16px}.value{fill:#edf3f7;font-size:28px;font-weight:750}",
        ".huge{fill:#49d6c8;font-size:58px;font-weight:800}",
        "</style>",
        f'<rect width="{WIDTH}" height="{HEIGHT}" fill="{BG}"/>',
        svg_text(70, 86, "DFlash on Windows: 2.56x Faster After the Runtime Fixes", "title"),
        svg_text(70, 128, "RTX 5090, native llama.cpp, July 14 2026. Decode speed excludes prompt prefill.", "subtitle"),
        f'<rect x="60" y="170" width="1680" height="330" rx="8" fill="{PANEL}"/>',
        svg_text(90, 225, "Comparable 10K BookContext before / after", "section"),
        svg_text(90, 264, "Same 8,907-token prompt, 1,024 generated tokens, temperature 0, ctx=200000", "subtitle"),
    ]
    left, plot_width, scale = 480, 980, 70.0
    for tick in (0, 10, 20, 30, 40, 50, 60, 70):
        x = left + plot_width * tick / scale
        parts.append(f'<line x1="{x:.1f}" y1="286" x2="{x:.1f}" y2="452" stroke="{GRID}"/>')
        parts.append(svg_text(int(x), 476, str(tick), "detail", "middle"))
    for index, row in enumerate(headline):
        y = 315 + index * 82
        color = BEFORE if index == 0 else AFTER
        width = plot_width * float(row["decode_tps"]) / scale
        parts.append(f'<text x="90" y="{y + 26}" fill="{color}" font-size="22" font-weight="700">{esc(row["stage"])}</text>')
        parts.append(f'<rect x="{left}" y="{y}" width="{width:.1f}" height="38" rx="5" fill="{color}"/>')
        parts.append(svg_text(int(left + width + 14), y + 29, f'{float(row["decode_tps"]):.2f} tok/s', "value"))
    parts.extend([
        svg_text(1500, 343, f"{improvement:.2f}x", "huge"),
        svg_text(1510, 385, f"+{gain:.0f}%", "value"),
        svg_text(1498, 426, "decode throughput", "detail"),
        svg_text(70, 580, "How the 1K tuning progressed", "section"),
        svg_text(70, 618, "All bars below use the same 1,174-token prose prompt and 1,024 generated tokens.", "subtitle"),
        f'<rect x="60" y="635" width="1680" height="403" rx="8" fill="{PANEL}"/>',
    ])
    tuning = [row for row in rows if row["section"] == "tuning"]
    left, plot_width, scale = 610, 980, 75.0
    for tick in (0, 15, 30, 45, 60, 75):
        x = left + plot_width * tick / scale
        parts.append(f'<line x1="{x:.1f}" y1="680" x2="{x:.1f}" y2="982" stroke="{GRID}"/>')
        parts.append(svg_text(int(x), 1010, str(tick), "detail", "middle"))
    for index, row in enumerate(tuning):
        y = 700 + index * 62
        if index == 0:
            color = BEFORE
        elif row["stage"] == "Target-only reference":
            color = REFERENCE
        elif index == len(tuning) - 2:
            color = AFTER
        else:
            color = INTERMEDIATE
        width = plot_width * float(row["decode_tps"]) / scale
        parts.append(svg_text(90, y + 25, row["stage"], "label"))
        parts.append(f'<rect x="{left}" y="{y}" width="{width:.1f}" height="30" rx="4" fill="{color}"/>')
        parts.append(svg_text(int(left + width + 12), y + 25, f'{float(row["decode_tps"]):.2f}', "label"))
    control = next(row for row in rows if row["section"] == "control")
    parts.extend([
        '<rect x="60" y="1085" width="1680" height="170" rx="8" fill="#15252a" stroke="#49d6c8" stroke-width="2"/>',
        '<text x="90" y="1145" fill="#49d6c8" font-size="30" font-weight="750">Separate coding control</text>',
        svg_text(90, 1190, "Short Python BST prompt", "label"),
        svg_text(440, 1180, f'{float(control["decode_tps"]):.2f} tok/s', "huge"),
        svg_text(860, 1165, "73.74% acceptance | mean accepted length 11.74", "body"),
        svg_text(860, 1200, "Not comparable to long-context bars; shows upside when predictions match.", "detail"),
        svg_text(70, 1340, "What changed", "section"),
    ])
    changes = [
        ("1", "Correct device placement", "Pinned both models to CUDA0; verified 65/65 target and 6/6 draft layers on the RTX 5090."),
        ("2", "Acceptance feedback fix", "Routed verification results to the per-slot DFlash state so adaptation receives real acceptance data."),
        ("3", "GPU-only adaptive bypass", "After four cycles below mean accepted length 3, stop speculative work for that request."),
        ("4", "Hidden-capture fast gate", "Stop unused hidden-state GPU-to-host copies after bypass; re-enable before the next request."),
        ("5", "Fail-fast placement check", "Abort before benchmarking if either model is partial or the draft lands on CUDA1."),
    ]
    y = 1360
    for number, heading, explanation in changes:
        parts.append(f'<rect x="70" y="{y}" width="46" height="46" rx="5" fill="{AFTER}"/>')
        parts.append(f'<text x="93" y="{y + 32}" fill="{BG}" font-size="22" font-weight="750" text-anchor="middle">{number}</text>')
        parts.append(svg_text(140, y + 22, heading, "label"))
        parts.append(svg_text(140, y + 48, explanation, "detail"))
        y += 84
    parts.extend([
        svg_text(70, 1805, "Before used draft ngl=1 and was CPU-heavy. After remains GPU-only; low-acceptance requests bypass DFlash, not CUDA.", "detail"),
        svg_text(1730, 1805, "neko-legends/nvidia-local-llm-profiles", "detail", "end"),
        "</svg>",
    ])
    SVG_PATH.write_text("\n".join(parts) + "\n", encoding="utf-8")


def main() -> None:
    rows = load_rows()
    render_png(rows)
    render_svg(rows)
    print(PNG_PATH)
    print(SVG_PATH)


if __name__ == "__main__":
    main()
