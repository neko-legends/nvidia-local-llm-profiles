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
OUTPUT_SVG_PATH = OUTPUT_DIR / "aeon-ornith-windows-docker-vs-gguf.svg"
OUTPUT_PNG_PATH = OUTPUT_DIR / "aeon-ornith-windows-docker-vs-gguf.png"
TIMING_CSV = RESULTS_DIR / "generation-timing-breakdowns-20260624.csv"
PUBLISHED_MTP_FILE = "ornith-1.0-35b-aeon-ultimate-uncensored-nvfp4-gguf-mtp.gguf"

DOCKER_COLOR = "#f2a23a"
DOCKER_EDGE = "#ffd99c"
GGUF_COLOR = "#42d0c4"
GGUF_EDGE = "#bdf9f4"
MTP_COLOR = "#7bd66f"
MTP_EDGE = "#d4ffcb"
BACKGROUND = "#101317"
PANEL = "#181e25"
TEXT = "#edf3f7"
MUTED = "#a8b2bd"
GRID = "#303842"

SOURCE_FILES = {
    "docker_10k_cold": "aeon-ornith-1.0-35b-nvfp4-vllm-ct-nvfp4-ctx256k-prompt10k-gen1024-20260627-175103.csv",
    "docker_10k_warm": "aeon-ornith-1.0-35b-nvfp4-vllm-ct-nvfp4-ctx256k-prompt10k-gen1024-warm-20260627-180627.csv",
    "docker_200k": "aeon-ornith-1.0-35b-nvfp4-vllm-ct-nvfp4-ctx256k-prompt200k-gen1024-20260627-175219.csv",
    "gguf_10k": "aeon-ornith-1.0-35b-nvfp4-gguf-llamacpp-native-nvfp4-ctx256k-prompt10k-gen1024-20260627-190202.csv",
    "gguf_200k": "aeon-ornith-1.0-35b-nvfp4-gguf-llamacpp-native-nvfp4-ctx256k-prompt200k-gen1024-20260627-190223.csv",
    "mtp_10k": "aeon-ornith-1.0-35b-nvfp4-aeon-mtp-temp06-llamacpp-ctx262k-prompt10k-gen1024-20260628-101704.csv",
    "mtp_200k": "aeon-ornith-1.0-35b-nvfp4-aeon-mtp-temp06-llamacpp-ctx262k-prompt200k-gen1024-20260628-101715.csv",
}


def fnum(value: str | None) -> float:
    return float(value) if value not in ("", None) else math.nan


def read_row(name: str) -> dict[str, str]:
    path = RESULTS_DIR / SOURCE_FILES[name]
    if not path.exists():
        raise FileNotFoundError(f"Missing benchmark CSV: {path}")

    with path.open(newline="", encoding="utf-8-sig") as handle:
        measured = [
            row
            for row in csv.DictReader(handle)
            if row.get("warmup", "").lower() not in ("true", "1", "yes")
        ]

    if not measured:
        raise ValueError(f"No measured benchmark rows found in {path}")

    return measured[-1]


def read_native_timing(model: str, filename: str, context_tokens: int) -> dict[str, str]:
    if not TIMING_CSV.exists():
        raise FileNotFoundError(f"Missing timing CSV: {TIMING_CSV}")

    with TIMING_CSV.open(newline="", encoding="utf-8-sig") as handle:
        matches = [
            row
            for row in csv.DictReader(handle)
            if row["model"] == model
            and row["file"] == filename
            and int(row["context_tokens"]) == context_tokens
        ]

    if not matches:
        raise ValueError(f"No native GGUF timing row found for {model} / {filename} / {context_tokens} tokens")

    return matches[-1]


def fmt_one(value: float) -> str:
    return str(Decimal(str(value)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP))


def fmt_signed_one(value: float) -> str:
    sign = "+" if value >= 0 else ""
    return f"{sign}{fmt_one(value)}"


def fmt_seconds(value: float) -> str:
    return f"{fmt_one(value)}s"


def svg_text(x: float, y: float, text: str, **attrs: object) -> str:
    pairs = []
    for key, value in attrs.items():
        attr_name = key[:-1] if key.endswith("_") else key.replace("_", "-")
        pairs.append(f'{attr_name}="{html.escape(str(value))}"')
    attr = " ".join(pairs)
    return f'<text x="{x:.1f}" y="{y:.1f}" {attr}>{html.escape(text)}</text>'


def load_chart_rows() -> tuple[list[dict[str, object]], dict[str, str]]:
    docker_10k = read_row("docker_10k_warm")
    docker_10k_cold = read_row("docker_10k_cold")
    docker_200k = read_row("docker_200k")
    gguf_10k = read_row("gguf_10k")
    gguf_200k = read_row("gguf_200k")
    mtp_10k = read_row("mtp_10k")
    mtp_200k = read_row("mtp_200k")
    gguf_10k_timing = read_native_timing(
        "AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4",
        "aeon-ornith-1.0-35b-nvfp4.gguf",
        8905,
    )
    gguf_200k_timing = read_native_timing(
        "AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4",
        "aeon-ornith-1.0-35b-nvfp4.gguf",
        174588,
    )
    mtp_10k_timing = read_native_timing(
        "AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4",
        PUBLISHED_MTP_FILE,
        8905,
    )
    mtp_200k_timing = read_native_timing(
        "AEON-7/Ornith-1.0-35B-AEON-Ultimate-Uncensored-NVFP4",
        PUBLISHED_MTP_FILE,
        174588,
    )

    rows = [
        {
            "group": "10K prompt",
            "detail": f'{int(fnum(docker_10k["prompt_tokens"])):,} prompt tokens',
            "runtime": "Docker / vLLM",
            "value": fnum(docker_10k["wall_completion_tps"]),
            "metric": "wall proxy",
            "wall": fnum(docker_10k["wall_seconds"]),
            "color": DOCKER_COLOR,
            "edge": DOCKER_EDGE,
        },
        {
            "group": "10K prompt",
            "detail": f'{int(fnum(gguf_10k["prompt_tokens"])):,} prompt tokens',
            "runtime": "Native GGUF / llama.cpp",
            "value": fnum(gguf_10k_timing["generation_tps"]),
            "metric": "decode",
            "wall_tps": fnum(gguf_10k["wall_completion_tps"]),
            "wall": fnum(gguf_10k["wall_seconds"]),
            "prefill": fnum(gguf_10k_timing["prompt_eval_seconds"]),
            "color": GGUF_COLOR,
            "edge": GGUF_EDGE,
        },
        {
            "group": "10K prompt",
            "detail": f'{int(fnum(mtp_10k["prompt_tokens"])):,} prompt tokens',
            "runtime": "Native Ultimate Uncensored MTP",
            "value": fnum(mtp_10k_timing["generation_tps"]),
            "metric": "decode",
            "wall_tps": fnum(mtp_10k["wall_completion_tps"]),
            "wall": fnum(mtp_10k["wall_seconds"]),
            "prefill": fnum(mtp_10k_timing["prompt_eval_seconds"]),
            "color": MTP_COLOR,
            "edge": MTP_EDGE,
        },
        {
            "group": "200K prompt",
            "detail": f'{int(fnum(docker_200k["prompt_tokens"])):,} prompt tokens',
            "runtime": "Docker / vLLM",
            "value": fnum(docker_200k["wall_completion_tps"]),
            "metric": "wall proxy",
            "wall": fnum(docker_200k["wall_seconds"]),
            "color": DOCKER_COLOR,
            "edge": DOCKER_EDGE,
        },
        {
            "group": "200K prompt",
            "detail": f'{int(fnum(gguf_200k["prompt_tokens"])):,} prompt tokens',
            "runtime": "Native GGUF / llama.cpp",
            "value": fnum(gguf_200k_timing["generation_tps"]),
            "metric": "decode",
            "wall_tps": fnum(gguf_200k["wall_completion_tps"]),
            "wall": fnum(gguf_200k["wall_seconds"]),
            "prefill": fnum(gguf_200k_timing["prompt_eval_seconds"]),
            "color": GGUF_COLOR,
            "edge": GGUF_EDGE,
        },
        {
            "group": "200K prompt",
            "detail": f'{int(fnum(mtp_200k["prompt_tokens"])):,} prompt tokens',
            "runtime": "Native Ultimate Uncensored MTP",
            "value": fnum(mtp_200k_timing["generation_tps"]),
            "metric": "decode",
            "wall_tps": fnum(mtp_200k["wall_completion_tps"]),
            "wall": fnum(mtp_200k["wall_seconds"]),
            "prefill": fnum(mtp_200k_timing["prompt_eval_seconds"]),
            "color": MTP_COLOR,
            "edge": MTP_EDGE,
        },
    ]

    notes = {
        "cold_10k": fmt_one(fnum(docker_10k_cold["wall_completion_tps"])),
        "mtp_10k_lift": fmt_signed_one((fnum(mtp_10k_timing["generation_tps"]) / fnum(gguf_10k_timing["generation_tps"]) - 1) * 100),
        "mtp_200k_lift": fmt_signed_one((fnum(mtp_200k_timing["generation_tps"]) / fnum(gguf_200k_timing["generation_tps"]) - 1) * 100),
        "docker_200k_lift": fmt_one((fnum(docker_200k["wall_completion_tps"]) / fnum(gguf_200k["wall_completion_tps"]) - 1) * 100),
        "native_200k_decode": fmt_one(fnum(gguf_200k_timing["generation_tps"])),
        "mtp_10k_decode": fmt_one(fnum(mtp_10k_timing["generation_tps"])),
        "mtp_200k_decode": fmt_one(fnum(mtp_200k_timing["generation_tps"])),
        "mtp_200k_wall": fmt_one(fnum(mtp_200k["wall_completion_tps"])),
        "native_200k_prefill": fmt_one(fnum(gguf_200k_timing["prompt_eval_seconds"])),
        "native_200k_wall": fmt_one(fnum(gguf_200k["wall_completion_tps"])),
        "prompt_hash_10k": docker_10k["prompt_sha256"],
        "prompt_hash_200k": docker_200k["prompt_sha256"],
    }
    return rows, notes


def render_svg(rows: list[dict[str, object]], notes: dict[str, str]) -> Path:
    width = 1680
    height = 1120
    left = 520
    right = 130
    top = 278
    plot_w = width - left - right
    row_gap = 74
    group_gap = 70
    bar_h = 38
    scale_max = 160

    y_positions: list[float] = []
    y = top
    current_group = ""
    for row in rows:
        if current_group and row["group"] != current_group:
            y += group_gap
        current_group = str(row["group"])
        y_positions.append(y)
        y += row_gap

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        "<style>",
        "text{font-family:Segoe UI,Arial,sans-serif;letter-spacing:0}",
        ".title{fill:#edf3f7;font-size:40px;font-weight:750}",
        ".subtitle{fill:#bcc6cf;font-size:20px}",
        ".group{fill:#edf3f7;font-size:24px;font-weight:750}",
        ".runtime{fill:#edf3f7;font-size:20px;font-weight:700}",
        ".detail{fill:#8f9aa6;font-size:15px}",
        ".value{fill:#edf3f7;font-size:22px;font-weight:750}",
        ".small{fill:#a8b2bd;font-size:16px}",
        ".note{fill:#cdd5dd;font-size:18px}",
        ".axis{fill:#9ca7b2;font-size:15px}",
        "</style>",
        f'<rect width="{width}" height="{height}" fill="{BACKGROUND}"/>',
        f'<rect x="{left - 28}" y="{top - 70}" width="{plot_w + 60}" height="560" rx="10" fill="{PANEL}"/>',
    ]

    parts.append(svg_text(72, 78, "AEON Ornith Ultimate Uncensored NVFP4 on Windows", class_="title"))
    parts.append(svg_text(72, 118, "Docker vLLM compressed-tensors vs native GGUF llama.cpp on RTX 5090", class_="subtitle"))
    parts.append(svg_text(72, 154, "All rows use the AEON Ultimate Uncensored NVFP4 source; MTP bars are the published neko-legends GGUF-MTP artifact.", class_="small"))
    parts.append(svg_text(72, 182, "Native bars show llama.cpp decode speed at temperature 0.6. Docker/vLLM bars are full-wall proxy because the decode split was not captured.", class_="small"))

    for tick in range(0, scale_max + 1, 20):
        x = left + (tick / scale_max) * plot_w
        parts.append(f'<line x1="{x:.1f}" y1="{top - 46}" x2="{x:.1f}" y2="{top + 512}" stroke="{GRID}" stroke-width="1"/>')
        parts.append(svg_text(x, top + 544, str(tick), class_="axis", text_anchor="middle"))

    group_seen: set[str] = set()
    for row, ypos in zip(rows, y_positions):
        group = str(row["group"])
        if group not in group_seen:
            group_seen.add(group)
            parts.append(svg_text(72, ypos - 42, group, class_="group"))
            parts.append(svg_text(72, ypos - 16, str(row["detail"]), class_="detail"))

        value = float(row["value"])
        wall = float(row["wall"])
        bar_w = (value / scale_max) * plot_w
        parts.append(svg_text(left - 28, ypos + 4, str(row["runtime"]), class_="runtime", text_anchor="end"))
        parts.append(f'<rect x="{left}" y="{ypos - 28}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="{row["color"]}" opacity="0.97"/>')
        parts.append(f'<rect x="{left}" y="{ypos - 28}" width="{bar_w:.1f}" height="{bar_h}" rx="5" fill="none" stroke="{row["edge"]}" stroke-opacity="0.72"/>')
        parts.append(svg_text(left + bar_w + 14, ypos - 2, f'{fmt_one(value)} {row["metric"]} tok/s', class_="value"))
        detail = f"{fmt_seconds(wall)} wall"
        if row["metric"] == "decode":
            detail = f'{detail}; {fmt_one(float(row["wall_tps"]))} wall tok/s; prefill {fmt_one(float(row["prefill"]))}s'
        else:
            detail = f"{detail}; decode split n/a"
        parts.append(svg_text(left + bar_w + 14, ypos + 24, detail, class_="small"))

    note_y = 862
    parts.append(svg_text(72, note_y, "Do not compare Docker bars as decode speed: vLLM only gave us full request wall timing for this run.", class_="note"))
    parts.append(svg_text(72, note_y + 34, f'AEON-trunk MTP changed native decode by {notes["mtp_10k_lift"]}% at 10K and {notes["mtp_200k_lift"]}% at 200K; 200K wall was {notes["mtp_200k_wall"]} tok/s after long prefill.', class_="note"))
    parts.append(svg_text(72, note_y + 68, f'10K tuning with draft-mtp n_max=2 reached 133.7 decode tok/s; chart bars use one temp=0.6 n_max=3+ngram profile.', class_="note"))
    parts.append(svg_text(72, note_y + 102, f'Docker first 10K request was {notes["cold_10k"]} tok/s because Triton JIT compilation landed in the timed request.', class_="note"))
    parts.append(svg_text(72, height - 42, "Source CSVs: results/rtx-5090, prompt hashes match for the 10K and 200K fixtures.", class_="small"))
    parts.append(svg_text(width - 72, height - 42, "neko-legends/nvidia-local-llm-profiles", class_="small", text_anchor="end"))
    parts.append("</svg>")

    svg = "\n".join(parts) + "\n"
    svg = re.sub(r"[ \t]+\n", "\n", svg)
    OUTPUT_SVG_PATH.write_text(svg, encoding="utf-8")
    return OUTPUT_SVG_PATH


def render_png(rows: list[dict[str, object]], notes: dict[str, str]) -> Path:
    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError as exc:
        raise SystemExit("Pillow is required to render the PNG chart.") from exc

    width = 1680
    height = 1120
    left = 520
    top = 278
    plot_w = width - left - 130
    row_gap = 74
    group_gap = 70
    bar_h = 38
    scale_max = 160

    image = Image.new("RGB", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(image)
    font_dir = Path("C:/Windows/Fonts")

    def font(name: str, size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
        path = font_dir / name
        if path.exists():
            return ImageFont.truetype(str(path), size)
        return ImageFont.load_default()

    title_font = font("segoeuib.ttf", 40)
    subtitle_font = font("segoeui.ttf", 20)
    group_font = font("segoeuib.ttf", 24)
    runtime_font = font("segoeuib.ttf", 20)
    detail_font = font("segoeui.ttf", 15)
    value_font = font("segoeuib.ttf", 22)
    small_font = font("segoeui.ttf", 16)
    note_font = font("segoeui.ttf", 18)

    draw.rounded_rectangle([left - 28, top - 70, left - 28 + plot_w + 60, top - 70 + 560], radius=10, fill=PANEL)
    draw.text((72, 46), "AEON Ornith Ultimate Uncensored NVFP4 on Windows", fill=TEXT, font=title_font)
    draw.text((72, 101), "Docker vLLM compressed-tensors vs native GGUF llama.cpp on RTX 5090", fill="#bcc6cf", font=subtitle_font)
    draw.text((72, 141), "All rows use the AEON Ultimate Uncensored NVFP4 source; MTP bars are the published neko-legends GGUF-MTP artifact.", fill=MUTED, font=small_font)
    draw.text((72, 169), "Native bars show llama.cpp decode speed at temperature 0.6. Docker/vLLM bars are full-wall proxy because the decode split was not captured.", fill=MUTED, font=small_font)

    for tick in range(0, scale_max + 1, 20):
        x = left + (tick / scale_max) * plot_w
        draw.line([(x, top - 46), (x, top + 512)], fill=GRID, width=1)
        text = str(tick)
        bbox = draw.textbbox((0, 0), text, font=small_font)
        draw.text((x - (bbox[2] - bbox[0]) / 2, top + 525), text, fill="#9ca7b2", font=small_font)

    y_positions: list[int] = []
    y = top
    current_group = ""
    for row in rows:
        if current_group and row["group"] != current_group:
            y += group_gap
        current_group = str(row["group"])
        y_positions.append(y)
        y += row_gap

    group_seen: set[str] = set()
    for row, ypos in zip(rows, y_positions):
        group = str(row["group"])
        if group not in group_seen:
            group_seen.add(group)
            draw.text((72, ypos - 70), group, fill=TEXT, font=group_font)
            draw.text((72, ypos - 40), str(row["detail"]), fill="#8f9aa6", font=detail_font)

        value = float(row["value"])
        wall = float(row["wall"])
        bar_w = (value / scale_max) * plot_w
        runtime = str(row["runtime"])
        bbox = draw.textbbox((0, 0), runtime, font=runtime_font)
        draw.text((left - 28 - (bbox[2] - bbox[0]), ypos - 22), runtime, fill=TEXT, font=runtime_font)
        draw.rounded_rectangle([left, ypos - 28, left + bar_w, ypos - 28 + bar_h], radius=5, fill=str(row["color"]), outline=str(row["edge"]), width=1)
        draw.text((left + bar_w + 14, ypos - 29), f'{fmt_one(value)} {row["metric"]} tok/s', fill=TEXT, font=value_font)
        detail = f"{fmt_seconds(wall)} wall"
        if row["metric"] == "decode":
            detail = f'{detail}; {fmt_one(float(row["wall_tps"]))} wall tok/s; prefill {fmt_one(float(row["prefill"]))}s'
        else:
            detail = f"{detail}; decode split n/a"
        draw.text((left + bar_w + 14, ypos - 1), detail, fill=MUTED, font=small_font)

    note_y = 862
    draw.text((72, note_y), "Do not compare Docker bars as decode speed: vLLM only gave us full request wall timing for this run.", fill="#cdd5dd", font=note_font)
    draw.text((72, note_y + 38), f'AEON-trunk MTP changed native decode by {notes["mtp_10k_lift"]}% at 10K and {notes["mtp_200k_lift"]}% at 200K; 200K wall was {notes["mtp_200k_wall"]} tok/s after long prefill.', fill="#cdd5dd", font=note_font)
    draw.text((72, note_y + 76), "10K tuning with draft-mtp n_max=2 reached 133.7 decode tok/s; chart bars use one temp=0.6 n_max=3+ngram profile.", fill="#cdd5dd", font=note_font)
    draw.text((72, note_y + 114), f'Docker first 10K request was {notes["cold_10k"]} tok/s because Triton JIT compilation landed in the timed request.', fill="#cdd5dd", font=note_font)
    draw.text((72, height - 56), "Source CSVs: results/rtx-5090, prompt hashes match for the 10K and 200K fixtures.", fill=MUTED, font=small_font)
    repo = "neko-legends/nvidia-local-llm-profiles"
    bbox = draw.textbbox((0, 0), repo, font=small_font)
    draw.text((width - 72 - (bbox[2] - bbox[0]), height - 56), repo, fill=MUTED, font=small_font)

    image.save(OUTPUT_PNG_PATH)
    return OUTPUT_PNG_PATH


def render() -> tuple[Path, Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rows, notes = load_chart_rows()
    svg = render_svg(rows, notes)
    png = render_png(rows, notes)
    return svg, png


if __name__ == "__main__":
    for path in render():
        print(path)
