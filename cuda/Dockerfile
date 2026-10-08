# Saina model server for NVIDIA GPUs, with Saina Helm 0.8B weights baked in.
# Built for fast cold starts on GPU clouds (RunPod and similar): no download at start,
# no network needed except the optional Cloudflare tunnel. See cuda/README.md.
ARG BASE=public.ecr.aws/docker/library/python:3.12-slim
FROM ${BASE} AS build
ARG SAINA_SPEC="saina[local,server]==0.1.2"
# CUDA 12.6 wheels bundle their own CUDA libraries and run on drivers from 560 up.
ARG TORCH_INDEX=https://download.pytorch.org/whl/cu126
ARG CHECKPOINT=run-saina/saina-helm-0.8b
ARG REVISION=e82055b348d02bb43552ccba88eda24835ba6baf
ARG CLOUDFLARED_VERSION=2026.10.0
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
RUN python -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
RUN pip install --index-url ${TORCH_INDEX} 'torch>=2.5,<3'
COPY wheels/ /wheels/
RUN pip install --find-links /wheels "${SAINA_SPEC}" \
 && site=/opt/venv/lib/python3.12/site-packages \
 && rm -rf $site/torch/test $site/torch/include
# Pinned weights, fetched once at build time.
RUN python -c "from huggingface_hub import snapshot_download as d; d('${CHECKPOINT}', revision='${REVISION}', local_dir='/models/helm', allow_patterns=['*.json','*.safetensors','*.txt','*.model','*.jinja','*.tiktoken'])" \
 && rm -rf /models/helm/.cache
RUN curl -fsSL -o /usr/local/bin/cloudflared \
      https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-amd64 \
 && chmod +x /usr/local/bin/cloudflared \
 && (pip uninstall -y pip setuptools wheel >/dev/null 2>&1 || true)

FROM ${BASE}
ARG REVISION=e82055b348d02bb43552ccba88eda24835ba6baf
COPY --from=build /opt/venv /opt/venv
COPY --from=build /models /models
COPY --from=build /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY cuda/entrypoint.sh /usr/local/bin/saina-entrypoint
RUN useradd --create-home --uid 10001 saina && chmod 755 /usr/local/bin/saina-entrypoint
USER saina
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    HF_HUB_OFFLINE=1 \
    SAINA_CHECKPOINT=/models/helm \
    SAINA_REVISION=${REVISION} \
    SAINA_DEVICE=cuda:0 \
    SAINA_MAX_LENGTH=8192 \
    SAINA_PORT=8000
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=5s --start-period=5m --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=4)"
ENTRYPOINT ["saina-entrypoint"]
