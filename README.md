# Saina deploy

Run a Saina model server (`POST /v1/ask`) on your own infrastructure. You run it,
so your data stays with you.

The image `ghcr.io/run-saina/saina-server` is model-agnostic and contains no
weights. On first start it downloads the selected model's pinned Hugging Face
revision into a cache volume; later starts take seconds.

## Docker Compose

```sh
export SAINA_API_KEY=$(openssl rand -hex 32)
docker compose up -d          # http://127.0.0.1:8000, healthy once the model is loaded
```

```sh
curl http://127.0.0.1:8000/v1/ask \
  -H "Authorization: Bearer $SAINA_API_KEY" -H 'Content-Type: application/json' \
  -d '{"model":"saina-helm-0.8b","state":"I was charged twice.","questions":{"team":{"type":"single_choice","question":"Which team?","options":{"billing":"Billing","technical":"Technical","other":"Other"}}}}'
```

The port binds to localhost only. Put TLS in front before exposing it.

## Models

Each file in `models/` pins one model. Pick one with `SAINA_MODEL`:

| `SAINA_MODEL` | Model | Download | RAM (CPU) |
|---|---|---|---|
| `helm-0.8b` (default) | [Saina Helm 0.8B](https://huggingface.co/run-saina/saina-helm-0.8b) | ~1.7 GB | ~4 GB |

To serve a local staged checkpoint, mount it read-only and set
`SAINA_CHECKPOINT` to its path inside the container.

## Configuration

| Variable | Purpose |
|---|---|
| `SAINA_API_KEY` | Required. Bearer token clients must send. |
| `SAINA_MODEL` | Which `models/*.env` to load (compose only). |
| `SAINA_CHECKPOINT`, `SAINA_REVISION` | Hub repo plus immutable commit, or a local path. |
| `SAINA_MAX_LENGTH` | Token limit. Longer inputs are rejected, never truncated. |
| `SAINA_PORT`, `SAINA_MEM_LIMIT` | Host port and memory cap (compose only). |

## Building

The image installs `saina` from PyPI at the version pinned in the `Dockerfile`.
To test an unreleased SDK, put its wheel in `wheels/` before building.

Releases are published by running the **Docker** workflow on `main`.
