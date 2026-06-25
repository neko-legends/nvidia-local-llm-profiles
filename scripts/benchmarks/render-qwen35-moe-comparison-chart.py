from __future__ import annotations

import csv
import html
import math
import re
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RESULTS_DIR = ROOT / "results" / "rtx-5090"
OUTPUT_DIR = ROOT / "assets" / "images"
OUTPUT_SVG_PATH = OUTPUT_DIR / "rtx-5090-qwen35-moe-vs-qwopus.svg"
OUTPUT_PNG_PATH = OUTPUT_DIR / "rtx-5090-qwen35-moe-vs-qwopus.png"

MOE_GLOB = "qwen36-35b-a3b-nvfp4-vllm-fp8kv-ctx200k-prompt*-gen1024-*.csv"
MANUAL_UI_CSV = RESULTS_DIR / "manual-unsloth-studio-ui-runs-20260624.csv"
TIMING_CSV = RESULTS_DIR / "generation-timing-breakdowns-20260624.csv"
MANUAL_UI_COLOR = "#ff7a90"


def fnum(value: str | None) -> float:
    return float(value) if value not in ("", None) else math.nan


def read_measured(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return [
            row
            for row in csv.DictReader(handle)
            if row.get("warmup", "").lower() not in ("true", "1", "yes")
        ]


def read_manual_ui_rows() -> list[dict[str, str]]:
    if not MANUAL_UI_CSV.exists():
        return []

    with MANUAL_UI_CSV.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def read_timing_rows() -> list[dict[str, str]]:
    if not TIMING_CSV.exists():
        return []

    with TIMING_CSV.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def paths_by_target(pattern: str) -> dict[int, list[Path]]:
    matches: dict[int, list[Path]] = {}
    for path in sorted(RESULTS_DIR.glob(pattern)):
        rows = read_measured(path)
        if not rows:
            continue
        target = int(rows[0]["target_prompt_tokens"])
        matches.setdefault(target, []).append(path)
    return matches


def latest_by_target(pattern: str) -> dict[int, Path]:
    return {target: paths[-1] for target, paths in paths_by_target(pattern).items()}


def avg_tps(path: Path) -> float:
    rows = read_measured(path)
    values = [fnum(row["wall_completion_tps"]) for row in rows]
    return sum(values) / len(values)


def fmt_one_decimal(value: float) -> str:
    return str(Decimal(str(value)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


def nearest(paths: dict[int, Path], target: int) -> tuple[int, Path] | None:
    if not paths:
        return None
    actual = min(paths, key=lambda value: abs(value - target))
    return actual, paths[actual]


def manual_rows_for(rows: list[dict[str, str]], model_prefix: str, target: int) -> list[dict[str, str]]:
    selected: list[dict[str, str]] = []
    for row in rows:
        if not row["model"].startswith(model_prefix):
            continue
        context_tokens = int(row["context_tokens"])
        if target < 50000 and context_tokens < 50000:
            selected.append(row)
        elif target >= 50000 and context_tokens >= 50000:
            selected.append(row)
    return selected


def timing_rows_for(rows: list[dict[str, str]], model_prefix: str, target: int) -> list[dict[str, str]]:
    selected: list[dict[str, str]] = []
    for row in rows:
        if not row["model"].startswith(model_prefix):
            continue
        context_tokens = int(row["context_tokens"])
        if target < 50000 and context_tokens < 50000:
            selected.append(row)
        elif target >= 50000 and context_tokens >= 50000:
            selected.append(row)
    return selected


def variant_label(filename: str) -> str:
    if "Q5_K_M" in filename:
        return "Q5_K_M"
    if "Q4_K_M" in filename:
        return "Q4_K_M"
    if "UD-Q4_K_XL" in filename:
        return "UD-Q4_K_XL"
    return filename.removesuffix(".gguf")


def prompt_read_label(row: dict[str, str]) -> str:
    seconds = row.get("prompt_eval_seconds", "")
    if not seconds:
        return "prompt read n/a"
    prefix = "~" if "estimate" in row.get("timing_source", "").lower() else ""
    return f"prompt read {prefix}{fmt_one_decimal(fnum(seconds))}s"


def manual_detail(row: dict[str, str]) -> str:
    context_tokens = int(row["context_tokens"])
    prompt_mode = row["prompt_mode"].replace(" in UI", "")
    prompt_read = ""
    if row.get("prompt_eval_seconds"):
        prompt_read = f"; prompt read {fmt_one_decimal(fnum(row['prompt_eval_seconds']))}s"
    return f'{variant_label(row["file"])} - {context_label(context_tokens)} - {prompt_mode} (Unsloth Studio){prompt_read}'


def context_label(tokens: int) -> str:
    if tokens >= 1000 and tokens % 1000:
        return f"{tokens / 1000:.1f}k"
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


def add_timing_row(
    rows: list[dict[str, object]],
    *,
    group: str,
    row: dict[str, str],
    color: str,
) -> None:
    tps = fnum(row["generation_tps"])
    if math.isnan(tps):
        return

    rows.append(
        {
            "group": group,
            "model": row["model"],
            "detail": f'{variant_label(row["file"])} - {context_label(int(row["context_tokens"]))} - generation only; {prompt_read_label(row)}',
            "target": int(row["context_tokens"]),
            "tps": tps,
            "path": TIMING_CSV.name,
            "color": color,
        }
    )


def add_full_request_row(
    rows: list[dict[str, object]],
    *,
    group: str,
    model: str,
    variant: str,
    target: int,
    path: Path,
    color: str,
) -> None:
    rows.append(
        {
            "group": group,
            "model": model,
            "detail": f"{variant} - {context_label(target)} reference - full request; timing split unavailable",
            "target": target,
            "tps": avg_tps(path),
            "path": path.name,
            "color": color,
        }
    )


def load_rows() -> tuple[list[dict[str, object]], int]:
    moe = latest_by_target(MOE_GLOB)
    manual_ui = read_manual_ui_rows()
    timing = read_timing_rows()

    rows: list[dict[str, object]] = []
    for label, target in (("Short context", 10000), ("Long context", 200000)):
        m = nearest(moe, target)
        for timing_row in timing_rows_for(timing, "Jackrong/", target):
            file = timing_row["file"]
            color = "#46d3c7" if "Q5_K_M" in file else "#69a8ff"
            add_timing_row(rows, group=label, row=timing_row, color=color)
        for manual in manual_rows_for(manual_ui, "Jackrong/", target):
                context_tokens = int(manual["context_tokens"])
                rows.append(
                    {
                        "group": label,
                        "model": manual["model"],
                        "detail": manual_detail(manual),
                        "target": context_tokens,
                        "tps": fnum(manual["completion_tps"]),
                        "path": MANUAL_UI_CSV.name,
                        "color": MANUAL_UI_COLOR,
                    }
                )
        for timing_row in timing_rows_for(timing, "unsloth/", target):
            add_timing_row(rows, group=label, row=timing_row, color="#9d82ff")
        for manual in manual_rows_for(manual_ui, "unsloth/", target):
                context_tokens = int(manual["context_tokens"])
                rows.append(
                    {
                        "group": label,
                        "model": manual["model"],
                        "detail": manual_detail(manual),
                        "target": context_tokens,
                        "tps": fnum(manual["completion_tps"]),
                        "path": MANUAL_UI_CSV.name,
                        "color": MANUAL_UI_COLOR,
                    }
                )
        for timing_row in timing_rows_for(timing, "deepreinforce-ai/", target):
            add_timing_row(rows, group=label, row=timing_row, color="#7edc72")
        for manual in manual_rows_for(manual_ui, "deepreinforce-ai/", target):
                context_tokens = int(manual["context_tokens"])
                rows.append(
                    {
                        "group": label,
                        "model": manual["model"],
                        "detail": manual_detail(manual),
                        "target": context_tokens,
                        "tps": fnum(manual["completion_tps"]),
                        "path": MANUAL_UI_CSV.name,
                        "color": MANUAL_UI_COLOR,
                    }
                )
        if m:
            add_full_request_row(
                rows,
                group=label,
                model="nvidia/Qwen3.6-35B-A3B-NVFP4",
                variant="modelopt NVFP4",
                target=m[0],
                path=m[1],
                color="#f2b846",
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
        ".sourceTag{fill:#261218;font-size:15px;font-weight:750}",
        ".axis{fill:#9aa5b1;font-size:15px}",
        "</style>",
        f'<rect width="{width}" height="{height}" fill="#111418"/>',
        f'<rect x="{left - 26}" y="{top - 52}" width="{plot_w + 56}" height="{height - top - 72}" rx="10" fill="#181e25"/>',
    ]

    parts.append(svg_text(72, 82, "RTX 5090: local coding-model throughput", class_="title"))
    parts.append(svg_text(72, 122, "Bars show generation speed where captured. Prompt read / prefill seconds are labeled separately and are not in those bars.", class_="subtitle"))

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
        if row["path"] == MANUAL_UI_CSV.name:
            tag = "Studio" if bar_w < 150 else "Unsloth Studio"
            parts.append(svg_text(left + 14, ypos - 2, tag, class_="sourceTag"))
        parts.append(svg_text(left + bar_w + 12, ypos + 2, fmt_one_decimal(value), class_="value"))
        parts.append(svg_text(left + bar_w + 70, ypos + 2, "tok/s", class_="small"))

    footnote = "vLLM rows are full-request timing because the prompt/generation split was not captured. UI accounting may differ from endpoint benches."
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
    source_font = font("segoeuib.ttf", 15)

    draw.rounded_rectangle(
        [left - 26, top - 52, left - 26 + plot_w + 56, height - 72],
        radius=10,
        fill="#181e25",
    )
    draw.text((72, 48), "RTX 5090: local coding-model throughput", fill="#edf3f7", font=title_font)
    draw.text(
        (72, 104),
        "Bars show generation speed where captured. Prompt read / prefill seconds are labeled separately and are not in those bars.",
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
        if row["path"] == MANUAL_UI_CSV.name:
            tag = "Studio" if bar_w < 150 else "Unsloth Studio"
            draw.text((left + 14, ypos - 18), tag, fill="#261218", font=source_font)
        draw.text((left + bar_w + 12, ypos - 23), fmt_one_decimal(value), fill="#edf3f7", font=value_font)
        draw.text((left + bar_w + 70, ypos - 18), "tok/s", fill="#9aa5b1", font=small_font)

    footnote = "vLLM rows are full-request timing because the prompt/generation split was not captured. UI accounting may differ from endpoint benches."
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
