from __future__ import annotations

import argparse
import shutil
from datetime import datetime
from pathlib import Path


QWOPUS_MODEL = "qwopus3.6-27b-coder-mtp-q5-k-m"
DIFFUSION_MODEL = "diffusiongemma"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Install the Hermes Local 5090 provider.")
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--provider-name", default="Local 5090")
    parser.add_argument("--router-port", default="39190")
    parser.add_argument("--qwopus-base-url", default="http://127.0.0.1:39182/v1")
    parser.add_argument("--diffusiongemma-base-url", default="http://127.0.0.1:8890/v1")
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
    }
    base_urls = {
        "http://127.0.0.1:39190/v1",
        "http://127.0.0.1:39182/v1",
        "http://127.0.0.1:8890/v1",
    }
    models = {
        QWOPUS_MODEL,
        "qwopus",
        "qwopus-coder",
        "diffusiongemma",
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
