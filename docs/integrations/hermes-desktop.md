# Hermes Desktop And Client

Hermes can use these LocalAI launchers through OpenAI-compatible `/v1` endpoints.

## Qwen3.6 Text NVFP4 MTP

Use this when you want the ModelOpt NVFP4/vLLM path.

Start:

```text
D:\Tools\LocalAI\start-qwen3.6-27B-Text-NVFP4-MTP-server.bat
```

Hermes settings:

```text
Provider/API: OpenAI-compatible chat completions
Base URL:     http://127.0.0.1:8892/v1
API key:      none or any placeholder if required
Model:        qwen3.6-27b-text-nvfp4-mtp
```

## Qwopus3.6 Coder MTP GGUF

Use this when you want the GGUF/llama.cpp CUDA path.

Start:

```text
D:\Tools\LocalAI\start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Hermes Desktop on the same machine:

```text
Provider/API: OpenAI-compatible chat completions
Base URL:     http://127.0.0.1:39182/v1
API key:      none or any placeholder if required
Model:        qwopus3.6-27b-coder-mtp-q5-k-m
```

Hermes Client from another machine:

```text
LAN base URL:       http://192.168.68.73:39182/v1
Tailscale base URL: http://100.64.131.86:39182/v1
Model:              qwopus3.6-27b-coder-mtp-q5-k-m
```

If the client cannot connect, run this once as admin:

```text
D:\Tools\LocalAI\allow-qwopus3.6-coder-mtp-server-firewall-admin.bat
```

## Verify An Endpoint

With a server running:

```powershell
Invoke-RestMethod http://127.0.0.1:39182/v1/models
```

Minimal chat request:

```powershell
$body = @{
  model = "qwopus3.6-27b-coder-mtp-q5-k-m"
  messages = @(@{ role = "user"; content = "Reply with only: OK" })
  max_tokens = 8
} | ConvertTo-Json -Depth 8

Invoke-RestMethod `
  -Uri http://127.0.0.1:39182/v1/chat/completions `
  -Method Post `
  -ContentType "application/json" `
  -Body $body
```

Swap the URL and model for the Qwen NVFP4 endpoint when testing that launcher.

## Notes

- Start the model server before Hermes tries to use it.
- Do not put a real API key in a local no-auth endpoint.
- Restart Hermes Desktop after changing saved custom provider settings.
- Keep provider names explicit so the UI makes it clear which backend is active.
