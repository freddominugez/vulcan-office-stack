# aiproxy

An OpenAI-compatible HTTP shim that fronts the Vulcan AI gateway
(`admin.byvulcan.com/api/ai-gateway`). The editor's AI plugin points at it, so the
editor can offer AI features without ever holding a provider key: the plugin talks to
`http://aiproxy:8800`, and this process adds `x-vulcan-secret` server-side.

It exposes just enough of the OpenAI surface: `GET /health`, `GET /v1/models`, and
`POST /v1/chat/completions`. Models advertised: `vulcan-office`, `vulcan-fast`,
`vulcan-full`.

## Why it is in this repository

It was found running on the production host on 2026-07-12 as `vo-aiproxy`, mounted
from `/home/ubuntu/aiproxy` and **absent from `docker-compose.yml`** — undocumented
drift. A teardown of the stack would have silently removed the editor's AI features
along with it. It is declared in the compose file now so it stops being invisible.

## Licence boundary

This is an **independent program**, not a derivative of the Document Server. It shares
no code with it and communicates only over HTTP. Shipping it alongside the AGPL
Document Server in this repository is mere aggregation and does not place it under the
AGPL — the same boundary the proprietary `vulcan-drive` app relies on.

## Configuration

All of it from the environment; nothing is baked in.

| Variable | Meaning |
|---|---|
| `VULCAN_PLATFORM_SECRET` | Sent upstream as `x-vulcan-secret`. **Required.** |
| `GATEWAY_URL` | Vulcan AI gateway endpoint. |
| `PRODUCT` | Sent upstream as `x-product-id`. `vulcan-office` here. |
| `MODELS` | Comma-separated list advertised on `/v1/models`. |
| `DEFAULT_TASK_TYPE` | Task type when the caller does not set one. |
