# Saina deploy

Run a Saina model server (`POST /v1/ask`) on your own infrastructure. You run it,
so your data stays with you.

The image `ghcr.io/run-saina/saina-server` is model-agnostic and contains no
weights. On first start it downloads the selected model's pinned Hugging Face
revision into a cache volume; later starts take seconds.

## Docker run

Pull the released image and start one container. The key you export here is the
bearer token clients send.

```sh
export SAINA_API_KEY=$(openssl rand -hex 32)
docker run -d --name saina \
  -p 127.0.0.1:8000:8000 \
  -e SAINA_API_KEY=$SAINA_API_KEY \
  -e SAINA_CHECKPOINT=run-saina/saina-helm-0.8b \
  -e SAINA_REVISION=e82055b348d02bb43552ccba88eda24835ba6baf \
  -e SAINA_MAX_LENGTH=8192 \
  -v saina-hf-cache:/cache \
  --memory 8g --restart unless-stopped \
  ghcr.io/run-saina/saina-server:0.1.0
```

The first start downloads the pinned weights (~1.7 GB) into the `saina-hf-cache`
volume. Check it with the `curl` below once `docker logs saina` shows the model loaded.
The values for `SAINA_CHECKPOINT` and `SAINA_REVISION` are the ones in
`models/helm-0.8b.env`; Compose reads that file for you.

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

Or point the hosted [playground](https://saina.run/playground) at `http://127.0.0.1:8000`
with the same key. It runs in your browser and talks to your server directly.

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
| `SAINA_CORS_ORIGINS` | Browser origins allowed to call the API. Default `https://saina.run` (the playground). Empty disables. |
| `SAINA_PORT`, `SAINA_MEM_LIMIT` | Host port and memory cap (compose only). |

## Building

The image installs `saina` from PyPI at the version pinned in the `Dockerfile`.
To test an unreleased SDK, put its wheel in `wheels/` before building.

Releases are published by running the **Docker** workflow on `main`.
