from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any


QWOPUS_MODEL = "qwopus3.6-27b-coder-mtp-q5-k-m"
QWOPUS35_MODEL = "qwopus3.6-35b-a3b-coder-mtp-q5-k-m"
DIFFUSION_MODEL = "diffusiongemma"
ORNITH_MODEL = "ornith-1.0-35b-q4-k-m"
ORNITH_Q5_MODEL = "ornith-1.0-35b-q5-k-m"
AEON_ORNITH_NVFP4_MODEL = "aeon-ornith-1.0-35b-nvfp4"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="OpenAI-compatible model router for Hermes Desktop.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=39190)
    parser.add_argument("--qwopus-base-url", default="http://127.0.0.1:39182/v1")
    parser.add_argument("--qwopus35-base-url", default="http://127.0.0.1:39191/v1")
    parser.add_argument("--diffusiongemma-base-url", default="http://127.0.0.1:8890/v1")
    parser.add_argument("--ornith-base-url", default="http://127.0.0.1:39188/v1")
    parser.add_argument("--ornith-q5-base-url", default="http://127.0.0.1:39189/v1")
    parser.add_argument("--aeon-ornith-nvfp4-base-url", default="http://127.0.0.1:39187/v1")
    return parser.parse_args()


def normalize_model(value: object) -> str:
    return str(value or "").strip().lower()


class Local5090Router(BaseHTTPRequestHandler):
    server_version = "Local5090Router/1.0"

    qwopus_base_url: str
    qwopus35_base_url: str
    diffusiongemma_base_url: str
    ornith_base_url: str
    ornith_q5_base_url: str
    aeon_ornith_nvfp4_base_url: str

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
                        "id": QWOPUS35_MODEL,
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
            QWOPUS35_MODEL: self.qwopus35_base_url,
            "qwopus35": self.qwopus35_base_url,
            "qwopus-35b": self.qwopus35_base_url,
            "qwopus35-coder": self.qwopus35_base_url,
            "qwopus3.6-35b-coder": self.qwopus35_base_url,
            "qwopus3.6-35b-a3b-coder": self.qwopus35_base_url,
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
        return aliases.get(normalize_model(model))

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

        target_base_url = self._target_base_url(normalize_model(payload.get("model")))
        if not target_base_url:
            self._send_json(
                400,
                {
                    "error": {
                        "message": "Unknown local model. Use diffusiongemma or "
                        f"{QWOPUS_MODEL}, {QWOPUS35_MODEL}, {ORNITH_MODEL}, {ORNITH_Q5_MODEL}, "
                        f"or {AEON_ORNITH_NVFP4_MODEL}."
                    }
                },
            )
            return

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
    Local5090Router.diffusiongemma_base_url = args.diffusiongemma_base_url
    Local5090Router.ornith_base_url = args.ornith_base_url
    Local5090Router.ornith_q5_base_url = args.ornith_q5_base_url
    Local5090Router.aeon_ornith_nvfp4_base_url = args.aeon_ornith_nvfp4_base_url

    server = ThreadingHTTPServer((args.host, args.port), Local5090Router)
    print(f"Local 5090 router listening at http://{args.host}:{args.port}/v1", flush=True)
    server.serve_forever()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
