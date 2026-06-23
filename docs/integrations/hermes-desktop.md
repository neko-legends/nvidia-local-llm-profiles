# Hermes Desktop Integration

Hermes can use the Qwopus local server through its OpenAI-compatible `/v1` endpoint.

## Qwopus3.6-27B-Coder-MTP Q5_K_M

Start the server (from the installed folder):

```bat
start-qwopus3.6-27b-coder-mtp-q5-server.bat
```

Wire into Hermes (same machine):

```text
Provider/API: OpenAI-compatible chat completions
Base URL:     http://127.0.0.1:39182/v1
API key:      none (or any placeholder)
Model:        qwopus3.6-27b-coder-mtp-q5-k-m
```

Hermes CLI shortcut:

```
/provider add custom:qwopus-local http://127.0.0.1:39182/v1 local
/model custom:qwopus-local:qwopus3.6-27b-coder-mtp-q5-k-m
```

Remote access from another machine on the LAN:

```text
Base URL:  http://<your-server-lan-ip>:39182/v1
Model:     qwopus3.6-27b-coder-mtp-q5-k-m
```

If the client cannot connect, run once as admin on the server:

```bat
allow-qwopus3.6-coder-mtp-server-firewall-admin.bat
```

## Verify the Endpoint

```powershell
Invoke-RestMethod http://127.0.0.1:39182/v1/models

$body = @{
  model = "qwopus3.6-27b-coder-mtp-q5-k-m"
  messages = @(@{ role = "user"; content = "Reply with only: OK" })
  max_tokens = 8
} | ConvertTo-Json -Depth 8

Invoke-RestMethod -Uri http://127.0.0.1:39182/v1/chat/completions `
  -Method Post -ContentType "application/json" -Body $body
```

## Notes

- Start the model server before Hermes tries to use it.
- Do not put a real API key in a local no-auth endpoint.
- Restart Hermes Desktop after changing saved custom provider settings.
- Server takes ~30s to load and start accepting requests after launch.
