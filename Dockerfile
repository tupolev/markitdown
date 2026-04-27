# syntax=docker/dockerfile:1.7

# Docker image/project name: markitdown
#
# This image clones Microsoft's MarkItDown repository and exposes the official
# `markitdown` CLI as the container entrypoint.

FROM python:3.13-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    EXIFTOOL_PATH=/usr/bin/exiftool \
    FFMPEG_PATH=/usr/bin/ffmpeg

ARG MARKITDOWN_REPO=https://github.com/microsoft/markitdown.git
ARG MARKITDOWN_REF=main

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        git \
        ffmpeg \
        exiftool \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone --depth 1 --branch "${MARKITDOWN_REF}" "${MARKITDOWN_REPO}" markitdown

WORKDIR /opt/markitdown

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
        "packages/markitdown[all]" \
        "packages/markitdown-sample-plugin" \
        markitdown-ocr \
        openai

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--help"]
