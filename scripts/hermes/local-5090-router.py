from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


QWOPUS_MODEL = "qwopus3.6-27b-coder-mtp-q5-k-m"
QWOPUS35_Q5_MODEL = "qwopus3.6-35b-a3b-coder-mtp-q5-k-m"
QWOPUS35_Q4_MODEL = "qwopus3.6-35b-a3b-coder-mtp-q4-k-m"
QWOPUS35_Q5_ALIASES = frozenset(
    {
        QWOPUS35_Q5_MODEL,
        "qwopus35",
        "qwopus-35b",
        "qwopus35-coder",
        "qwopus3.6-35b-coder",
        "qwopus3.6-35b-a3b-coder",
        "qwopus35-q5",
        "qwopus-35b-q5",
        "qwopus35-coder-q5",
        "qwopus3.6-35b-coder-q5",
        "qwopus3.6-35b-a3b-coder-q5",
    }
)
QWOPUS35_Q4_ALIASES = frozenset(
    {
        QWOPUS35_Q4_MODEL,
        "qwopus35-q4",
        "qwopus-35b-q4",
        "qwopus35-coder-q4",
        "qwopus3.6-35b-coder-q4",
        "qwopus3.6-35b-a3b-coder-q4",
    }
)
QWOPUS35_NO_THINK_ALIASES = QWOPUS35_Q5_ALIASES | QWOPUS35_Q4_ALIASES
DIFFUSION_MODEL = "diffusiongemma"
ORNITH_MODEL = "ornith-1.0-35b-q4-k-m"
ORNITH_Q5_MODEL = "ornith-1.0-35b-q5-k-m"
AEON_ORNITH_NVFP4_MODEL = "aeon-ornith-1.0-35b-nvfp4"
QWEN36_27B_NVFP4_MODEL = "qwen36-27b-nvfp4-mtp-gguf"
UNSLOTH_QWEN36_27B_NVFP4_MODEL = "qwen36-27b-unsloth-nvfp4-mtp-gguf"
UNSLOTH_QWEN36_35B_NVFP4_MODEL = "qwen36-35b-a3b-unsloth-nvfp4-mtp-gguf"
THINKINGCAP_QWEN36_27B_MODEL = "thinkingcap-qwen36-27b-q4-k-m"
QWEN36_27B_NVFP4_ALIASES = frozenset(
    {
        QWEN36_27B_NVFP4_MODEL,
        "qwen36-27b-nvfp4-gguf",
        "qwen36-27b",
        "qwen36-27b-nvfp4",
        "qwen36-27b-gguf",
        "qwen36-27b-mtp-gguf",
        "qwen3.6-27b",
        "qwen3.6-27b-nvfp4",
        "qwen3.6-27b-nvfp4-gguf",
        "qwen3.6-27b-nvfp4-mtp-gguf",
        "nvidia-qwen36-27b-nvfp4",
        "nvidia-qwen3.6-27b-nvfp4",
        "nvidia/qwen3.6-27b-nvfp4",
        "neko-legends/qwen3.6-27b-nvfp4-mtp-gguf",
    }
)
UNSLOTH_QWEN36_27B_NVFP4_ALIASES = frozenset(
    {
        UNSLOTH_QWEN36_27B_NVFP4_MODEL,
        "unsloth-qwen36-27b-nvfp4",
        "unsloth-qwen3.6-27b-nvfp4",
        "unsloth/qwen3.6-27b-nvfp4",
        "qwen36-27b-unsloth",
        "qwen3.6-27b-unsloth-nvfp4",
    }
)
UNSLOTH_QWEN36_35B_NVFP4_ALIASES = frozenset(
    {
        UNSLOTH_QWEN36_35B_NVFP4_MODEL,
        "unsloth-qwen36-35b-a3b-nvfp4",
        "unsloth-qwen3.6-35b-a3b-nvfp4",
        "unsloth/qwen3.6-35b-a3b-nvfp4",
        "qwen36-35b-unsloth",
        "qwen3.6-35b-a3b-unsloth-nvfp4",
    }
)
THINKINGCAP_QWEN36_27B_ALIASES = frozenset(
    {
        THINKINGCAP_QWEN36_27B_MODEL,
        "thinkingcap-qwen36-27b",
        "thinkingcap-qwen3.6-27b",
        "thinkingcap-qwen36-27b-q4",
        "thinkingcap-qwen36-27b-q4-k-m",
        "bottlecapai/thinkingcap-qwen3.6-27b-gguf",
        "bottlecapai/thinkingcap-qwen3.6-27b-gguf:q4_k_m",
    }
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="OpenAI-compatible model router for Hermes Desktop.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=39190)
    parser.add_argument("--qwopus-base-url", default="http://127.0.0.1:39182/v1")
    parser.add_argument("--qwopus35-base-url", default="http://127.0.0.1:39191/v1")
    parser.add_argument("--qwopus35-q4-base-url", default="http://127.0.0.1:39193/v1")
    parser.add_argument("--diffusiongemma-base-url", default="http://127.0.0.1:8890/v1")
    parser.add_argument("--ornith-base-url", default="http://127.0.0.1:39188/v1")
    parser.add_argument("--ornith-q5-base-url", default="http://127.0.0.1:39189/v1")
    parser.add_argument("--aeon-ornith-nvfp4-base-url", default="http://127.0.0.1:39187/v1")
    parser.add_argument("--qwen36-27b-nvfp4-base-url", default="http://127.0.0.1:39195/v1")
    parser.add_argument("--unsloth-qwen36-27b-nvfp4-base-url", default="http://127.0.0.1:39196/v1")
    parser.add_argument("--unsloth-qwen36-35b-nvfp4-base-url", default="http://127.0.0.1:39197/v1")
    parser.add_argument("--thinkingcap-qwen36-27b-base-url", default="http://127.0.0.1:39198/v1")
    return parser.parse_args()


def normalize_model(value: object) -> str:
    return str(value or "").strip().lower()


class Local5090Router(BaseHTTPRequestHandler):
    server_version = "Local5090Router/1.0"

    qwopus_base_url: str
    qwopus35_base_url: str
    qwopus35_q4_base_url: str
    diffusiongemma_base_url: str
    ornith_base_url: str
    ornith_q5_base_url: str
    aeon_ornith_nvfp4_base_url: str
    qwen36_27b_nvfp4_base_url: str
    unsloth_qwen36_27b_nvfp4_base_url: str
    unsloth_qwen36_35b_nvfp4_base_url: str
    thinkingcap_qwen36_27b_base_url: str

    def _models_response(self) -> bytes:
        return json.dumps(
            {
                "object": "list",
                "data": [
                    {
                        "id": DIFFUSION_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 64000,
                    },
                    {
                        "id": QWOPUS_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 262144,
                    },
                    {
                        "id": QWOPUS35_Q5_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 200000,
                    },
                    {
                        "id": QWOPUS35_Q4_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 200000,
                    },
                    {
                        "id": ORNITH_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 262144,
                    },
                    {
                        "id": ORNITH_Q5_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 262144,
                    },
                    {
                        "id": AEON_ORNITH_NVFP4_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 262144,
                    },
                    {
                        "id": QWEN36_27B_NVFP4_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 200000,
                    },
                    {
                        "id": UNSLOTH_QWEN36_27B_NVFP4_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 200000,
                    },
                    {
                        "id": UNSLOTH_QWEN36_35B_NVFP4_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 200000,
                    },
                    {
                        "id": THINKINGCAP_QWEN36_27B_MODEL,
                        "object": "model",
                        "created": 0,
                        "owned_by": "Local 5090",
                        "context_length": 200000,
                    },
                ],
            },
            separators=(",", ":"),
        ).encode("utf-8")

    def _send_json(self, status: int, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _target_base_url(self, model: str) -> str | None:
        aliases = {
            QWOPUS_MODEL: self.qwopus_base_url,
            "qwopus": self.qwopus_base_url,
            "qwopus-coder": self.qwopus_base_url,
            "qwopus-coder-q5": self.qwopus_base_url,
            DIFFUSION_MODEL: self.diffusiongemma_base_url,
            "diffusiongemma-med": self.diffusiongemma_base_url,
            "diffusiongemma med": self.diffusiongemma_base_url,
            ORNITH_MODEL: self.ornith_base_url,
            "ornith": self.ornith_base_url,
            "ornith-35b": self.ornith_base_url,
            "ornith-1.0-35b": self.ornith_base_url,
            "ornith-1.0-35b-gguf": self.ornith_base_url,
            ORNITH_Q5_MODEL: self.ornith_q5_base_url,
            "ornith-q5": self.ornith_q5_base_url,
            "ornith-35b-q5": self.ornith_q5_base_url,
            "ornith-1.0-35b-q5": self.ornith_q5_base_url,
            "ornith-1.0-35b-q5-k-m": self.ornith_q5_base_url,
            AEON_ORNITH_NVFP4_MODEL: self.aeon_ornith_nvfp4_base_url,
            "aeon-ornith": self.aeon_ornith_nvfp4_base_url,
            "aeon-ornith-35b": self.aeon_ornith_nvfp4_base_url,
            "aeon-ornith-nvfp4": self.aeon_ornith_nvfp4_base_url,
            "ornith-aeon-nvfp4": self.aeon_ornith_nvfp4_base_url,
            "ornith-1.0-35b-aeon-nvfp4": self.aeon_ornith_nvfp4_base_url,
        }
        aliases.update({alias: self.qwopus35_base_url for alias in QWOPUS35_Q5_ALIASES})
        aliases.update({alias: self.qwopus35_q4_base_url for alias in QWOPUS35_Q4_ALIASES})
        aliases.update({alias: self.qwen36_27b_nvfp4_base_url for alias in QWEN36_27B_NVFP4_ALIASES})
        aliases.update(
            {alias: self.unsloth_qwen36_27b_nvfp4_base_url for alias in UNSLOTH_QWEN36_27B_NVFP4_ALIASES}
        )
        aliases.update(
            {alias: self.unsloth_qwen36_35b_nvfp4_base_url for alias in UNSLOTH_QWEN36_35B_NVFP4_ALIASES}
        )
        aliases.update(
            {alias: self.thinkingcap_qwen36_27b_base_url for alias in THINKINGCAP_QWEN36_27B_ALIASES}
        )
        return aliases.get(normalize_model(model))

    def _apply_model_request_defaults(self, payload: dict[str, Any]) -> None:
        no_think_aliases = (
            QWOPUS35_NO_THINK_ALIASES
            | QWEN36_27B_NVFP4_ALIASES
            | UNSLOTH_QWEN36_27B_NVFP4_ALIASES
            | UNSLOTH_QWEN36_35B_NVFP4_ALIASES
            | THINKINGCAP_QWEN36_27B_ALIASES
        )
        if normalize_model(payload.get("model")) not in no_think_aliases:
            return

        chat_template_kwargs = payload.get("chat_template_kwargs")
        if not isinstance(chat_template_kwargs, dict):
            chat_template_kwargs = {}
            payload["chat_template_kwargs"] = chat_template_kwargs
        chat_template_kwargs.setdefault("enable_thinking", False)

    def _forward_headers(self) -> dict[str, str]:
        blocked = {
            "accept-encoding",
            "connection",
            "content-length",
            "host",
            "proxy-authenticate",
            "proxy-authorization",
            "te",
            "trailer",
            "transfer-encoding",
            "upgrade",
        }
        return {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in blocked
        }

    def _proxy_path(self) -> str:
        if self.path.startswith("/v1/"):
            return self.path[3:]
        if self.path == "/v1":
            return ""
        return self.path

    def do_GET(self) -> None:
        if self.path in {"/v1/models", "/models"}:
            body = self._models_response()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self._send_json(404, {"error": {"message": f"Unknown path: {self.path}"}})

    def do_POST(self) -> None:
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)

        try:
            payload = json.loads(body.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            self._send_json(400, {"error": {"message": "Request body must be JSON."}})
            return
        if not isinstance(payload, dict):
            self._send_json(400, {"error": {"message": "Request body must be a JSON object."}})
            return

        target_base_url = self._target_base_url(normalize_model(payload.get("model")))
        if not target_base_url:
            self._send_json(
                400,
                {
                    "error": {
                        "message": "Unknown local model. Use diffusiongemma or "
                        f"{QWOPUS_MODEL}, {QWOPUS35_Q5_MODEL}, {QWOPUS35_Q4_MODEL}, "
                        f"{ORNITH_MODEL}, {ORNITH_Q5_MODEL}, "
                        f"{AEON_ORNITH_NVFP4_MODEL}, {QWEN36_27B_NVFP4_MODEL}, or {THINKINGCAP_QWEN36_27B_MODEL}."
                    }
                },
            )
            return

        self._apply_model_request_defaults(payload)
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")

        target_url = target_base_url.rstrip("/") + self._proxy_path()
        request = urllib.request.Request(
            target_url,
            data=body,
            method="POST",
            headers=self._forward_headers() | {"Content-Type": "application/json"},
        )

        try:
            with urllib.request.urlopen(request, timeout=None) as response:
                self.send_response(response.status)
                for key, value in response.headers.items():
                    if key.lower() not in {"connection", "transfer-encoding"}:
                        self.send_header(key, value)
                self.end_headers()
                while True:
                    chunk = response.read(65536)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    self.wfile.flush()
        except urllib.error.HTTPError as exc:
            error_body = exc.read()
            self.send_response(exc.code)
            for key, value in exc.headers.items():
                if key.lower() not in {"connection", "transfer-encoding"}:
                    self.send_header(key, value)
            self.end_headers()
            self.wfile.write(error_body)
        except Exception as exc:
            self._send_json(502, {"error": {"message": f"Local model backend unavailable: {exc}"}})

    def log_message(self, format: str, *args: object) -> None:
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), format % args))


def main() -> int:
    args = parse_args()
    Local5090Router.qwopus_base_url = args.qwopus_base_url
    Local5090Router.qwopus35_base_url = args.qwopus35_base_url
    Local5090Router.qwopus35_q4_base_url = args.qwopus35_q4_base_url
    Local5090Router.diffusiongemma_base_url = args.diffusiongemma_base_url
    Local5090Router.ornith_base_url = args.ornith_base_url
    Local5090Router.ornith_q5_base_url = args.ornith_q5_base_url
    Local5090Router.aeon_ornith_nvfp4_base_url = args.aeon_ornith_nvfp4_base_url
    Local5090Router.qwen36_27b_nvfp4_base_url = args.qwen36_27b_nvfp4_base_url
    Local5090Router.unsloth_qwen36_27b_nvfp4_base_url = args.unsloth_qwen36_27b_nvfp4_base_url
    Local5090Router.unsloth_qwen36_35b_nvfp4_base_url = args.unsloth_qwen36_35b_nvfp4_base_url
    Local5090Router.thinkingcap_qwen36_27b_base_url = args.thinkingcap_qwen36_27b_base_url

    server = ThreadingHTTPServer((args.host, args.port), Local5090Router)
    print(f"Local 5090 router listening at http://{args.host}:{args.port}/v1", flush=True)
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
