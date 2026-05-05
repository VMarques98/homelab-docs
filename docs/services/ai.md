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
