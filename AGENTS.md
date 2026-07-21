# Repository agent instructions

Use `scripts/localai/model-profiles.json` and
`scripts/localai/manage-model-profile.ps1` as the authoritative model routing
and installation interface. Do not invent model paths, aliases, or runtime
flags.

Natural-language model requests should be mapped to a documented catalog ID or
alias, then confirmed with `-Action Show`. In particular:

- "Setup Laguna XS on my 5090", "install Laguna XS", and "run Laguna XS 2.1"
  mean the original Poolside Q4_K_M profile, catalog ID
  `laguna-xs-2.1-q4-k-m` (alias `laguna-xs`).
- Select `laguna-xs-2.1-q4-k-m-dflash` only when the user explicitly asks for
  Laguna DFlash or speculative decoding. DFlash uses separate drafter files; it
  does not modify or rebrand Poolside's target GGUF.

For a setup request:

1. Run `manage-model-profile.ps1 -Action Show -Model <alias> -Json`.
2. Run `-Action Install -Model <alias>` to inspect the ordered plan.
3. Check prerequisites and available disk space, then repeat with `-Execute`.
4. Install `scripts/hermes/install-local-5090-provider.bat` once if Hermes is
   part of the request.
5. Start the cataloged server, verify its `/v1/models` response, the model
   alias, and complete CUDA0 offload.

Downloaded weights belong in the checkout-parent `.local-model-cache` and must
never be committed.

