from __future__ import annotations

import argparse
import shutil
from datetime import datetime
from pathlib import Path


QWOPUS_MODEL = "qwopus3.6-27b-coder-mtp-q5-k-m"
QWOPUS35_Q5_MODEL = "qwopus3.6-35b-a3b-coder-mtp-q5-k-m"
QWOPUS35_Q4_MODEL = "qwopus3.6-35b-a3b-coder-mtp-q4-k-m"
DIFFUSION_MODEL = "diffusiongemma"
ORNITH_MODEL = "ornith-1.0-35b-q4-k-m"
ORNITH_Q5_MODEL = "ornith-1.0-35b-q5-k-m"
AEON_ORNITH_NVFP4_MODEL = "aeon-ornith-1.0-35b-nvfp4"
QWEN36_27B_NVFP4_MODEL = "qwen36-27b-nvfp4-mtp-gguf"
UNSLOTH_QWEN36_27B_NVFP4_MODEL = "qwen36-27b-unsloth-nvfp4-mtp-gguf"
UNSLOTH_QWEN36_35B_NVFP4_MODEL = "qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf"
UNSLOTH_QWEN36_35B_NVFP4_FAST_MODEL = "qwen36-35b-a3b-unsloth-nvfp4-fast-mtp-gguf"
THINKINGCAP_QWEN36_27B_MODEL = "thinkingcap-qwen36-27b-q4-k-m"
TERNARY_BONSAI_27B_MODEL = "ternary-bonsai-27b-dspark-q4-1"
QWEN36_27B_DFLASH_MODEL = "qwen36-27b-q4-k-m-dflash-q8-0"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install the Hermes Local 5090 provider.")
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--provider-name", default="Local 5090")
    parser.add_argument("--router-port", default="39190")
    parser.add_argument("--qwopus-base-url", default="http://127.0.0.1:39182/v1")
    parser.add_argument("--qwopus35-base-url", default="http://127.0.0.1:39191/v1")
    parser.add_argument("--diffusiongemma-base-url", default="http://127.0.0.1:8890/v1")
    parser.add_argument("--ornith-base-url", default="http://127.0.0.1:39188/v1")
    parser.add_argument("--ornith-q5-base-url", default="http://127.0.0.1:39189/v1")
    parser.add_argument("--aeon-ornith-nvfp4-base-url", default="http://127.0.0.1:39187/v1")
    parser.add_argument("--qwen36-27b-nvfp4-base-url", default="http://127.0.0.1:39195/v1")
    parser.add_argument("--unsloth-qwen36-27b-nvfp4-base-url", default="http://127.0.0.1:39196/v1")
    parser.add_argument("--unsloth-qwen36-35b-nvfp4-base-url", default="http://127.0.0.1:39197/v1")
    return parser.parse_args()


def require_yaml():
    try:
        import yaml  # type: ignore
    except ImportError as exc:
        raise SystemExit(
            "PyYAML is required to update Hermes config.yaml. "
            "Run this with Hermes' bundled Python, or install it with: pip install pyyaml"
        ) from exc
    return yaml


def provider_config(name: str, router_port: str) -> dict:
    return {
        "api_mode": "chat_completions",
        "base_url": f"http://127.0.0.1:{router_port}/v1",
        "discover_models": True,
        "model": QWOPUS_MODEL,
        "models": {
            DIFFUSION_MODEL: {
                "context_length": 64000,
                "supports_vision": False,
            },
            QWOPUS_MODEL: {
                "context_length": 262144,
                "supports_vision": False,
            },
            QWOPUS35_Q5_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
            QWOPUS35_Q4_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
            ORNITH_MODEL: {
                "context_length": 262144,
                "supports_vision": False,
            },
            ORNITH_Q5_MODEL: {
                "context_length": 262144,
                "supports_vision": False,
            },
            AEON_ORNITH_NVFP4_MODEL: {
                "context_length": 262144,
                "supports_vision": True,
            },
            QWEN36_27B_NVFP4_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
            UNSLOTH_QWEN36_27B_NVFP4_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
            UNSLOTH_QWEN36_35B_NVFP4_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
            UNSLOTH_QWEN36_35B_NVFP4_FAST_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
            THINKINGCAP_QWEN36_27B_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
            TERNARY_BONSAI_27B_MODEL: {
                "context_length": 16384,
                "supports_vision": False,
            },
            QWEN36_27B_DFLASH_MODEL: {
                "context_length": 200000,
                "supports_vision": False,
            },
        },
        "name": name,
    }


def should_remove_provider(provider: object, name: str) -> bool:
    if not isinstance(provider, dict):
        return False

    provider_name = str(provider.get("name", "")).lower()
    base_url = str(provider.get("base_url", "")).lower()
    model = str(provider.get("model", "")).lower()

    names = {
        name.lower(),
        "local 5090",
        "diffusiongemma-local",
        "qwopus-local",
        "qwopus35-local",
        "qwopus35-q4-local",
        "ornith-local",
        "ornith-q5-local",
        "aeon-ornith-local",
        "aeon-ornith-nvfp4-local",
        "qwen36-27b-local",
        "qwen36-27b-nvfp4-local",
        "qwen36-27b-nvfp4-mtp-local",
        "unsloth-qwen36-27b-nvfp4-local",
        "unsloth-qwen36-35b-nvfp4-local",
    }
    base_urls = {
        "http://127.0.0.1:39190/v1",
        "http://127.0.0.1:39182/v1",
        "http://127.0.0.1:39191/v1",
        "http://127.0.0.1:39193/v1",
        "http://127.0.0.1:8890/v1",
        "http://127.0.0.1:39188/v1",
        "http://127.0.0.1:39189/v1",
        "http://127.0.0.1:39187/v1",
        "http://127.0.0.1:39195/v1",
        "http://127.0.0.1:39196/v1",
        "http://127.0.0.1:39197/v1",
        "http://127.0.0.1:39198/v1",
        "http://127.0.0.1:39199/v1",
    }
    models = {
        QWOPUS_MODEL,
        "qwopus",
        "qwopus-coder",
        QWOPUS35_Q5_MODEL,
        "qwopus35",
        "qwopus-35b",
        "qwopus35-coder",
        "qwopus3.6-35b-coder",
        "qwopus3.6-35b-a3b-coder",
        QWOPUS35_Q4_MODEL,
        "qwopus35-q4",
        "qwopus-35b-q4",
        "qwopus35-coder-q4",
        "qwopus3.6-35b-coder-q4",
        "qwopus3.6-35b-a3b-coder-q4",
        "diffusiongemma",
        ORNITH_MODEL,
        "ornith",
        "ornith-35b",
        "ornith-1.0-35b",
        "ornith-1.0-35b-gguf",
        ORNITH_Q5_MODEL,
        "ornith-q5",
        "ornith-35b-q5",
        "ornith-1.0-35b-q5",
        "ornith-1.0-35b-q5-k-m",
        AEON_ORNITH_NVFP4_MODEL,
        "aeon-ornith",
        "aeon-ornith-35b",
        "aeon-ornith-nvfp4",
        "ornith-aeon-nvfp4",
        "ornith-1.0-35b-aeon-nvfp4",
        QWEN36_27B_NVFP4_MODEL,
        "qwen36-27b-nvfp4-gguf",
        "qwen36-27b-local",
        "qwen36-27b",
        "qwen36-27b-nvfp4",
        "qwen3.6-27b",
        "qwen3.6-27b-nvfp4",
        "nvidia-qwen36-27b-nvfp4",
        "nvidia/qwen3.6-27b-nvfp4",
        UNSLOTH_QWEN36_27B_NVFP4_MODEL,
        UNSLOTH_QWEN36_35B_NVFP4_MODEL,
        UNSLOTH_QWEN36_35B_NVFP4_FAST_MODEL,
        THINKINGCAP_QWEN36_27B_MODEL,
        TERNARY_BONSAI_27B_MODEL,
        QWEN36_27B_DFLASH_MODEL,
        "unsloth-qwen36-27b-nvfp4",
        "unsloth-qwen36-35b-a3b-nvfp4",
    }

    return provider_name in names or base_url in base_urls or model in models


def main() -> int:
    args = parse_args()
    yaml = require_yaml()

    args.config.parent.mkdir(parents=True, exist_ok=True)
    if args.config.exists():
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = args.config.with_name(f"{args.config.name}.bak-local5090-{timestamp}")
        shutil.copy2(args.config, backup)
        data = yaml.safe_load(args.config.read_text(encoding="utf-8")) or {}
    else:
        data = {}

    if not isinstance(data, dict):
        raise SystemExit(f"{args.config} is not a YAML mapping.")

    providers = data.get("custom_providers") or []
    if not isinstance(providers, list):
        providers = []

    providers = [
        provider
        for provider in providers
        if not should_remove_provider(provider, args.provider_name)
    ]
    providers.append(provider_config(args.provider_name, str(args.router_port)))
    data["custom_providers"] = providers

    args.config.write_text(
        yaml.safe_dump(data, sort_keys=False, allow_unicode=False),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
