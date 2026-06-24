from __future__ import annotations

import csv
import html
import math
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = ROOT / "results" / "rtx-5090"
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_SVG_PATH = OUTPUT_DIR / "rtx-5090-qwen35-moe-vs-qwopus.svg"
OUTPUT_PNG_PATH = OUTPUT_DIR / "rtx-5090-qwen35-moe-vs-qwopus.png"

QWOPUS_GLOB = "qwopus-coder-mtp-q5-ctx256k-mtp-prompt*-gen1024-*.csv"
MOE_GLOB = "qwen36-35b-a3b-nvfp4-vllm-fp8kv-ctx200k-prompt*-gen1024-*.csv"
GGUF_GLOB = "qwen36-35b-a3b-mtp-ud-q4-k-xl-llamacpp-ctx200k-prompt*-gen1024-*.csv"


def fnum(value: str | None) -> float:
    return float(value) if value not in ("", None) else math.nan


def read_measured(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return [
            row
            for row in csv.DictReader(handle)
            if row.get("warmup", "").lower() not in ("true", "1", "yes")
        ]


def paths_by_target(pattern: str) -> dict[int, list[Path]]:
    matches: dict[int, list[Path]] = {}
    for path in sorted(RESULTS_DIR.glob(pattern)):
        rows = read_measured(path)
        if not rows:
            continue
        target = int(rows[0]["target_prompt_tokens"])
        matches.setdefault(target, []).append(path)
    return matches


def earliest_by_target(pattern: str) -> dict[int, Path]:
    return {target: paths[0] for target, paths in paths_by_target(pattern).items()}


def latest_by_target(pattern: str) -> dict[int, Path]:
    return {target: paths[-1] for target, paths in paths_by_target(pattern).items()}


def avg_tps(path: Path) -> float:
    rows = read_measured(path)
    values = [fnum(row["wall_completion_tps"]) for row in rows]
    return sum(values) / len(values)


def nearest(paths: dict[int, Path], target: int) -> tuple[int, Path] | None:
    if not paths:
        return None
    actual = min(paths, key=lambda value: abs(value - target))
    return actual, paths[actual]


def context_label(tokens: int) -> str:
    if tokens >= 1000:
        return f"{round(tokens / 1000):.0f}k"
    return str(tokens)


def svg_text(x: float, y: float, text: str, **attrs: str) -> str:
    pairs = []
    for key, value in attrs.items():
        attr_name = key[:-1] if key.endswith("_") else key.replace("_", "-")
        pairs.append(f'{attr_name}="{html.escape(str(value))}"')
    attr = " ".join(pairs)
    return f'<text x="{x:.1f}" y="{y:.1f}" {attr}>{html.escape(text)}</text>'


def load_rows() -> tuple[list[dict[str, object]], int]:
    qwopus = latest_by_target(QWOPUS_GLOB)
    moe = latest_by_target(MOE_GLOB)
    gguf_display = earliest_by_target(GGUF_GLOB)
    gguf_headless = latest_by_target(GGUF_GLOB)

    rows: list[dict[str, object]] = []
    for label, target in (("Short context", 10000), ("Long context", 200000)):
        q = nearest(qwopus, 8192 if target == 10000 else target)
        m = nearest(moe, target)
        gd = nearest(gguf_display, target)
        gh = nearest(gguf_headless, target)
        if q:
            rows.append(
                {
                    "group": label,
                    "model": "Jackrong/Qwopus3.6-27B-Coder-MTP-GGUF",
                    "detail": f"Q5_K_M - {context_label(q[0])}",
                    "target": q[0],
                    "tps": avg_tps(q[1]),
                    "path": q[1].name,
                    "color": "#46d3c7",
                }
            )
        if gd:
            rows.append(
                {
                    "group": label,
                    "model": "unsloth/Qwen3.6-35B-A3B-MTP-GGUF",
                    "detail": f"UD-Q4_K_XL - {context_label(gd[0])} - 5090 display attached",
                    "target": gd[0],
                    "tps": avg_tps(gd[1]),
                    "path": gd[1].name,
                    "color": "#9d82ff",
                }
            )
        if gh and (not gd or gh[1] != gd[1]):
            rows.append(
                {
                    "group": label,
                    "model": "unsloth/Qwen3.6-35B-A3B-MTP-GGUF",
                    "detail": f"UD-Q4_K_XL - {context_label(gh[0])} - 5090 headless, display on 3090",
                    "target": gh[0],
                    "tps": avg_tps(gh[1]),
                    "path": gh[1].name,
                    "color": "#b993ff",
                }
            )
        if m:
            rows.append(
                {
                    "group": label,
                    "model": "nvidia/Qwen3.6-35B-A3B-NVFP4",
                    "detail": f"modelopt NVFP4 - {context_label(m[0])} - vLLM nightly",
                    "target": m[0],
                    "tps": avg_tps(m[1]),
                    "path": m[1].name,
                    "color": "#f2b846",
                }
            )

    if not rows:
        raise SystemExit("No Qwopus or Qwen 35B benchmark CSVs found.")

    max_value = max(float(row["tps"]) for row in rows)
    scale_max = max(25, math.ceil(max_value / 25) * 25)
    return rows, scale_max


def render_svg(rows: list[dict[str, object]], scale_max: int) -> Path:
    width = 1780
    height = 820
    left = 620
    right = 100
    top = 220
    row_gap = 80
    group_gap = 72
    bar_h = 34
    plot_w = width - left - right

    y_positions: list[float] = []
    y = top
    current_group = ""
    for row in rows:
        if current_group and row["group"] != current_group:
            y += group_gap
        current_group = str(row["group"])
        y_positions.append(y)
        y += row_gap

    height = int(max(height, y + 135))

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        "<style>",
        "text{font-family:Segoe UI,Arial,sans-serif;letter-spacing:0}",
        ".title{fill:#edf3f7;font-size:42px;font-weight:750}",
        ".subtitle{fill:#b5bec8;font-size:20px}",
        ".label{fill:#e8eef4;font-size:21px;font-weight:650}",
        ".small{fill:#9aa5b1;font-size:16px}",
        ".detail{fill:#7f8b98;font-size:14px}",
        ".value{fill:#edf3f7;font-size:21px;font-weight:750}",
        ".axis{fill:#9aa5b1;font-size:15px}",
        "</style>",
        f'<rect width="{width}" height="{height}" fill="#111418"/>',
        f'<rect x="{left - 26}" y="{top - 52}" width="{plot_w + 56}" height="{height - top - 72}" rx="10" fill="#181e25"/>',
    ]

    parts.append(svg_text(72, 82, "RTX 5090: local Qwen-family throughput", class_="title"))
    parts.append(svg_text(72, 122, "Average completion tokens per second. Purple bars compare the same Unsloth MTP GGUF with and without display output on the 5090.", class_="subtitle"))

    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        parts.append(f'<line x1="{x:.1f}" y1="{top - 38}" x2="{x:.1f}" y2="{height - 98}" stroke="#2f3742" stroke-width="1"/>')
        parts.append(svg_text(x, height - 70, str(tick), class_="axis", text_anchor="middle"))

    group_seen: set[str] = set()
    for row, ypos in zip(rows, y_positions):
        group = str(row["group"])
        if group not in group_seen:
            group_seen.add(group)
            parts.append(svg_text(72, ypos - 44, group, class_="label"))

        value = float(row["tps"])
        bar_w = (value / scale_max) * plot_w
        parts.append(svg_text(left - 28, ypos - 4, str(row["model"]), class_="small", text_anchor="end"))
        parts.append(svg_text(left - 28, ypos + 17, str(row["detail"]), class_="detail", text_anchor="end"))
        parts.append(f'<rect x="{left}" y="{ypos - 24}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="{row["color"]}" opacity="0.95"/>')
        parts.append(f'<rect x="{left}" y="{ypos - 24}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="none" stroke="#d9fff8" stroke-opacity="0.55"/>')
        parts.append(svg_text(left + bar_w + 12, ypos + 2, f"{value:.1f}", class_="value"))
        parts.append(svg_text(left + bar_w + 70, ypos + 2, "tok/s", class_="small"))

    footnote = "Source: results/rtx-5090 CSVs. Headless = RTX 5090 display_active Disabled; display output moved to RTX 3090."
    parts.append(svg_text(72, height - 34, footnote, class_="small"))
    parts.append(svg_text(width - 72, height - 34, "neko-legends/nvidia-local-llm-profiles", class_="small", text_anchor="end"))
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

    width = 1780
    height = 820
    left = 620
    right = 100
    top = 220
    row_gap = 80
    group_gap = 72
    bar_h = 34
    plot_w = width - left - right

    y_positions: list[int] = []
    y = top
    current_group = ""
    for row in rows:
        if current_group and row["group"] != current_group:
            y += group_gap
        current_group = str(row["group"])
        y_positions.append(y)
        y += row_gap

    height = int(max(height, y + 135))
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
    label_font = font("segoeuib.ttf", 21)
    small_font = font("segoeui.ttf", 16)
    detail_font = font("segoeui.ttf", 14)
    value_font = font("segoeuib.ttf", 21)

    draw.rounded_rectangle(
        [left - 26, top - 52, left - 26 + plot_w + 56, height - 72],
        radius=10,
        fill="#181e25",
    )
    draw.text((72, 48), "RTX 5090: local Qwen-family throughput", fill="#edf3f7", font=title_font)
    draw.text(
        (72, 104),
        "Average completion tokens per second. Purple bars compare the same Unsloth MTP GGUF with and without display output on the 5090.",
        fill="#b5bec8",
        font=subtitle_font,
    )

    for tick in range(0, scale_max + 1, 25):
        x = left + (tick / scale_max) * plot_w
        draw.line([(x, top - 38), (x, height - 98)], fill="#2f3742", width=1)
        tick_text = str(tick)
        bbox = draw.textbbox((0, 0), tick_text, font=small_font)
        draw.text((x - (bbox[2] - bbox[0]) / 2, height - 88), tick_text, fill="#9aa5b1", font=small_font)

    group_seen: set[str] = set()
    for row, ypos in zip(rows, y_positions):
        group = str(row["group"])
        if group not in group_seen:
            group_seen.add(group)
            draw.text((72, ypos - 70), group, fill="#e8eef4", font=label_font)

        value = float(row["tps"])
        bar_w = (value / scale_max) * plot_w
        label = str(row["model"])
        detail = str(row["detail"])
        bbox = draw.textbbox((0, 0), label, font=small_font)
        draw.text((left - 28 - (bbox[2] - bbox[0]), ypos - 27), label, fill="#9aa5b1", font=small_font)
        bbox = draw.textbbox((0, 0), detail, font=detail_font)
        draw.text((left - 28 - (bbox[2] - bbox[0]), ypos - 6), detail, fill="#7f8b98", font=detail_font)
        draw.rounded_rectangle(
            [left, ypos - 24, left + bar_w, ypos - 24 + bar_h],
            radius=5,
            fill=str(row["color"]),
            outline="#d9fff8",
            width=1,
        )
        draw.text((left + bar_w + 12, ypos - 23), f"{value:.1f}", fill="#edf3f7", font=value_font)
        draw.text((left + bar_w + 70, ypos - 18), "tok/s", fill="#9aa5b1", font=small_font)

    footnote = "Source: results/rtx-5090 CSVs. Headless = RTX 5090 display_active Disabled; display output moved to RTX 3090."
    draw.text((72, height - 54), footnote, fill="#9aa5b1", font=small_font)
    repo = "neko-legends/nvidia-local-llm-profiles"
    bbox = draw.textbbox((0, 0), repo, font=small_font)
    draw.text((width - 72 - (bbox[2] - bbox[0]), height - 54), repo, fill="#9aa5b1", font=small_font)
    image.save(OUTPUT_PNG_PATH)
    return OUTPUT_PNG_PATH


def render() -> tuple[Path, Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows, scale_max = load_rows()
    return render_svg(rows, scale_max), render_png(rows, scale_max)


if __name__ == "__main__":
    for path in render():
        print(path)
