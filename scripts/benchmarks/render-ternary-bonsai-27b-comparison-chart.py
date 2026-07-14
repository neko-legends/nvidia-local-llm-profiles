from __future__ import annotations

import importlib.util
import sys
from dataclasses import replace
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE_RENDERER = Path(__file__).with_name("render-qwen35-moe-comparison-chart.py")
SPEC = importlib.util.spec_from_file_location("rtx5090_field_chart", SOURCE_RENDERER)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError(f"Unable to load {SOURCE_RENDERER}")
field = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = field
SPEC.loader.exec_module(field)


def main() -> None:
    field.MODEL_SPECS = [
        field.ModelSpec(
            "prism-ml/Ternary-Bonsai-27B-gguf",
            "Ternary-Bonsai-27B-dspark-Q4_1.gguf",
            "Ternary-Bonsai 27B + DSpark Q4_1 (16K ctx)",
            "#ff735c",
            True,
        ),
        field.ModelSpec(
            "prism-ml/Ternary-Bonsai-27B-gguf",
            "Ternary-Bonsai-27B-Q2_0.gguf",
            "Ternary-Bonsai 27B Q2_0 target-only",
            "#f2b846",
            True,
        ),
        *(replace(spec, highlight=False) for spec in field.MODEL_SPECS),
    ]
    field.OUTPUT_SVG_PATH = ROOT / "assets" / "images" / "ternary-bonsai-27b-vs-rtx-5090-field-20260714.svg"
    field.OUTPUT_PNG_PATH = ROOT / "assets" / "images" / "ternary-bonsai-27b-vs-rtx-5090-field-20260714.png"
    field.CHART_TITLE = "Ternary-Bonsai 27B + DSpark vs RTX 5090 Field"
    field.CHART_SUBTITLE = "Benchmark snapshot: July 14, 2026. Native Windows llama.cpp decode speed; prompt prefill is separate."
    field.CHART_NOTE = "DSpark is shown at 10K only; its full-context staging cannot fit 200K on 32 GB. Target-only uses q4_0 KV at 262K context."
    field.CHART_FOOTER = "Same BookContext fixtures and temperature 0; 1024-token cap. DSpark reached EOS at 741 tokens."

    for path in field.render():
        print(path)


if __name__ == "__main__":
    main()
