# Saina model server (CPU). Model-agnostic: weights are not baked in. Pick a model
# at runtime with SAINA_CHECKPOINT + SAINA_REVISION (see models/*.env).
# Official Docker library image via AWS's public mirror (no Docker Hub rate limits).
ARG BASE=public.ecr.aws/docker/library/python:3.12-slim
FROM ${BASE} AS build
ARG SAINA_SPEC="saina[local,server]==0.1.1"
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
RUN python -m venv /opt/venv
ENV PATH=/opt/venv/bin:$PATH
# CPU-only torch avoids ~2 GB of CUDA libraries.
RUN pip install --index-url https://download.pytorch.org/whl/cpu 'torch>=2.5,<3'
# wheels/ is empty in releases (saina comes from PyPI); drop a local wheel there to
# test an unreleased SDK.
COPY wheels/ /wheels/
RUN pip install --find-links /wheels "${SAINA_SPEC}" \
 && site=/opt/venv/lib/python3.12/site-packages \
 && rm -rf $site/torch/test $site/torch/include \
 && pip uninstall -y pip setuptools wheel >/dev/null 2>&1 || true

FROM ${BASE}
COPY --from=build /opt/venv /opt/venv
RUN useradd --create-home --uid 10001 saina && mkdir -p /models /cache && chown saina /models /cache
USER saina
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    HF_HOME=/cache \
    SAINA_DEVICE=cpu
EXPOSE 8000
# The model loads before the server accepts connections, so a healthy response means ready.
HEALTHCHECK --interval=15s --timeout=5s --start-period=10m --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=4)"
CMD ["uvicorn", "saina.server:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000", "--workers", "1", "--no-access-log"]
