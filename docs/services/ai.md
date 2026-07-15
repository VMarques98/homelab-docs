# AI

## Open-WebUI

Chat frontend backed by Ollama. Supports multi-turn conversations, document uploads, and switching between installed models.

Runs on the Mac Mini and is accessible via the homelab reverse proxy.

---

## Ollama

Local LLM inference engine running natively on the Mac Mini M2 Pro.

The Apple M2 Pro's unified memory architecture provides fast inference for 7B–13B parameter models without the overhead of a separate VRAM limit.

**Common models:**

| Model | Use |
|-------|-----|
| `llama3.2` | General purpose |
| `mistral` | General purpose (fast) |
| `codellama` | Code generation |

**API:** Ollama exposes an OpenAI-compatible API endpoint on the local network.

---

## LiteLLM

A unified API proxy that exposes an OpenAI-compatible endpoint backed by Ollama. Useful for tools and applications that expect the OpenAI SDK format but should use the local model.

## Component breakdown

| Component | Role | Data boundary | Verification |
|---|---|---|---|
| Ollama | Local model runtime and inference | Model files and prompts remain on the Mac Mini unless an application sends them elsewhere | Query a health endpoint and run a small local inference. |
| Open-WebUI | User-facing chat and document interface | Uploaded documents require private storage and access review | Test login, model selection, and a representative chat/upload path. |
| LiteLLM | OpenAI-compatible routing layer | Requests pass through the configured local proxy and model backend | Verify routing, model availability, and error handling. |
| Hermes integrations | Future orchestration and review workflows | Personal/job/financial data must use separate private stores | Require explicit approval for external actions and preserve audit records. |

## Operations

Keep model storage, prompt data, and application credentials out of Git. Monitor disk usage and memory pressure on the Mac Mini. When changing models or proxy configuration, verify latency, context limits, error responses, and that requests reach the intended backend.

## Planned AI-assisted workflows

Hermes may assist the Job Hunter and Receipt Ingest projects described in [Potential Projects](../potential-projects.md), but local inference does not by itself guarantee privacy: inspect every upload, cloud API, browser automation, and export boundary.
