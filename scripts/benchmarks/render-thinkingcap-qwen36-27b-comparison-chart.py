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
            "bottlecapai/ThinkingCap-Qwen3.6-27B-GGUF",
            "ThinkingCap-Qwen3.6-27B-Q4_K_M.gguf",
            "ThinkingCap Qwen3.6 27B Q4_K_M MTP",
            "#ff735c",
            True,
        ),
        *(replace(spec, highlight=False) for spec in field.MODEL_SPECS),
    ]
    field.OUTPUT_SVG_PATH = ROOT / "assets" / "images" / "thinkingcap-qwen36-27b-vs-rtx-5090-field-20260714.svg"
    field.OUTPUT_PNG_PATH = ROOT / "assets" / "images" / "thinkingcap-qwen36-27b-vs-rtx-5090-field-20260714.png"
    field.CHART_TITLE = "ThinkingCap Qwen3.6 27B Q4_K_M vs RTX 5090 Field"
    field.CHART_SUBTITLE = "Benchmark snapshot: July 14, 2026. Native llama.cpp decode-only speed; prompt prefill is separate."
    field.CHART_NOTE = "ThinkingCap uses its bundled MTP head at n=4; all rows use native GGUF endpoints with no Docker/vLLM or UI-observed data."

    for path in field.render():
        print(path)


if __name__ == "__main__":
    main()
