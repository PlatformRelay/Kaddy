# REQ-CADDY-S05-02 — showcase content baked into an immutable multi-stage image.
# Stages: (1) mkdocs Material → /docs/  (2) slidev deck → /slides/
# Runtime: pinned Caddy serving static output only — no build toolchain.
#
# Build context: the REPO ROOT:
#   docker build -f deploy/showcase/Dockerfile .
#
# Test: tests/deck/showcase-image-build.sh

# --- docs stage: mkdocs Material → static site under /docs/ -----------------
FROM python:3.12.8-alpine AS docs
WORKDIR /src
COPY requirements-docs.txt ./
RUN pip install --no-cache-dir -r requirements-docs.txt
COPY mkdocs.yml ./
COPY docs/ ./docs/
RUN mkdocs build --strict && test -f site/index.html

# --- deck stage: slidev build → static SPA under /slides/ -------------------
FROM node:22.23.1-alpine AS build
WORKDIR /src/slides
# pnpm major matches CI (pnpm/action-setup version: 10)
RUN npm install -g pnpm@10
COPY slides/package.json slides/pnpm-lock.yaml slides/pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY slides/ ./
# --base /slides/ so the SPA's assets resolve when served under /slides/
RUN pnpm build --base /slides/ && test -f dist/index.html

# --- runtime stage: pinned Caddy, static files only ---------------------------
FROM caddy:2.11.4-alpine

# OCI provenance + ADR-0301 kaddy labels (bare keys are canonical)
LABEL org.opencontainers.image.title="kaddy-showcase" \
      org.opencontainers.image.description="kaddy showcase tenant: Slidev deck + MkDocs docs (demo site IS the pitch, D-030)" \
      org.opencontainers.image.source="https://github.com/PlatformRelay/Kaddy" \
      org.opencontainers.image.url="https://github.com/PlatformRelay/Kaddy" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.vendor="PlatformRelay" \
      owner=platform-team \
      service=kaddy-showcase \
      component=web \
      part-of=kaddy \
      managed-by=github-actions \
      data-classification=public \
      business-criticality=business-operational \
      track=stable

COPY deploy/showcase/Caddyfile /etc/caddy/Caddyfile
COPY deploy/showcase/index.html /srv/index.html
COPY --from=build /src/slides/dist/ /srv/slides/
COPY --from=docs /src/site/ /srv/docs/

# Non-root: :8080 is unprivileged; Caddy only needs writable XDG dirs (tmpfs-friendly)
ENV XDG_DATA_HOME=/tmp/caddy-data \
    XDG_CONFIG_HOME=/tmp/caddy-config
USER 65532:65532

EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
