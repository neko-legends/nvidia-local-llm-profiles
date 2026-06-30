from __future__ import annotations

import os
from pathlib import Path

from huggingface_hub import HfApi


ROOT = Path(__file__).resolve().parents[2]
CHECKOUT_PARENT = ROOT.parent

REPO_ID = os.environ.get("HF_REPO_ID", "neko-legends/Qwen3.6-35B-A3B-NVFP4-MTP-GGUF")
GGUF_PATH = Path(
    os.environ.get(
        "GGUF_PATH",
        CHECKOUT_PARENT
        / ".local-model-cache"
        / "nvidia"
        / "Qwen3.6-35B-A3B-NVFP4-MTP-GGUF"
        / "qwen3.6-35b-a3b-nvfp4-mtp.gguf",
    )
)
MODEL_CARD_PATH = ROOT / "docs" / "models" / "qwen36-35b-a3b-nvfp4-mtp-gguf.model-card.md"
CHART_PATH = ROOT / "assets" / "images" / "rtx-5090-qwen35-moe-vs-qwopus.png"
EXTRA_CHART_PATHS = [
    ROOT / "assets" / "images" / "qwen36-llamacpp-b9761-vs-b9851.png",
]
PROMPT_PATHS = [
    ROOT / "benchmarks" / "prompts" / "book-context-10k.txt",
    ROOT / "benchmarks" / "prompts" / "book-context-200k.txt",
    ROOT / "benchmarks" / "prompts" / "book-context-300k.txt",
]


def require_file(path: Path) -> Path:
    if not path.exists():
        raise FileNotFoundError(path)
    return path


def main() -> None:
    api = HfApi()
    api.upload_file(
        repo_id=REPO_ID,
        repo_type="model",
        path_or_fileobj=require_file(MODEL_CARD_PATH),
        path_in_repo="README.md",
        commit_message="Update model card with native GGUF benchmarks",
    )
    api.upload_file(
        repo_id=REPO_ID,
        repo_type="model",
        path_or_fileobj=require_file(CHART_PATH),
        path_in_repo=CHART_PATH.name,
        commit_message="Upload RTX 5090 benchmark chart",
    )
    for chart_path in EXTRA_CHART_PATHS:
        api.upload_file(
            repo_id=REPO_ID,
            repo_type="model",
            path_or_fileobj=require_file(chart_path),
            path_in_repo=chart_path.name,
            commit_message="Upload llama.cpp build comparison chart",
        )
    for prompt_path in PROMPT_PATHS:
        api.upload_file(
            repo_id=REPO_ID,
            repo_type="model",
            path_or_fileobj=require_file(prompt_path),
            path_in_repo=f"benchmark-prompts/{prompt_path.name}",
            commit_message="Upload benchmark prompt fixtures",
        )
    api.upload_file(
        repo_id=REPO_ID,
        repo_type="model",
        path_or_fileobj=require_file(GGUF_PATH),
        path_in_repo=GGUF_PATH.name,
        commit_message="Upload Qwen3.6 35B A3B NVFP4 MTP GGUF",
    )
    print(f"Uploaded {GGUF_PATH.name} and model card assets to {REPO_ID}")


if __name__ == "__main__":
    main()
