# GPU image (CUDA) with Helm baked in

`ghcr.io/run-saina/saina-server:<version>-cuda` runs the same server as the CPU image, on an
NVIDIA GPU, with the pinned Saina Helm 0.8B weights already inside. Nothing is downloaded at
start, so it's ready about as fast as the GPU can load 2 GB of weights. It's meant for GPU
clouds (RunPod, Vast, Lambda, any Docker host with the NVIDIA runtime).

```sh
docker run -d --gpus 1 -p 127.0.0.1:8000:8000 \
  -e SAINA_API_KEY=$(openssl rand -hex 32) \
  ghcr.io/run-saina/saina-server:0.1.2-cuda
```

It needs an NVIDIA driver that supports CUDA 12.6 (driver 560 or newer). The image is
linux/amd64 only and about 7 GB.

## Optional: Cloudflare tunnel

Set `TUNNEL_TOKEN` to a Cloudflare tunnel token and the container also runs `cloudflared`,
which connects out to Cloudflare and serves whatever hostname that tunnel's (dashboard-managed)
config routes to `http://localhost:8000`. No inbound port is needed. Saina uses this for its
own standby server.

## Configuration

Same variables as the CPU image (`SAINA_API_KEY`, `SAINA_CORS_ORIGINS`, `SAINA_MAX_LENGTH`),
plus `SAINA_PORT` (default `8000`) and `TUNNEL_TOKEN`. `SAINA_CHECKPOINT` points at the baked
weights (`/models/helm`) and `SAINA_REVISION` reports their pinned Hub revision on `/healthz`.

Build: the **Docker (CUDA)** workflow on `main`.
