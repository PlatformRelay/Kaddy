# REQ-CADDY-S05-02 — showcase content baked into an immutable image.
# Multi-stage: the build stage renders the Slidev deck (slides/, E12) to a
# static SPA; the runtime stage is a pinned Caddy serving ONLY static output —
# no node/pnpm/build toolchain in the runtime layer (scannable for E11).
#
# DEVIATION (honest): the spec's REQ also names `mkdocs build`. The root
# mkdocs.yml does NOT pass `mkdocs build --strict` today (24 broken-link
# warnings), so the docs half is deliberately NOT baked yet — shipping a
# known-broken docs build would be theater. Tracked in
# openspec/changes/e-caddy-mvp/tasks.md; /docs/ joins this image once the
# links are fixed (theme flip to material is the same follow-up).
#
# Build context: the REPO ROOT (the deck lives in slides/):
#   docker build -f deploy/showcase/Dockerfile .
#
# Test: tests/deck/showcase-image-build.sh (structural, offline; CI builds for real)

# --- build stage: slidev build → static SPA under /slides/ -------------------
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
      org.opencontainers.image.description="kaddy showcase tenant: the Slidev deck served as the demo site (the demo site IS the pitch, D-030)" \
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

# Non-root: :8080 is unprivileged; Caddy only needs writable XDG dirs (tmpfs-friendly)
ENV XDG_DATA_HOME=/tmp/caddy-data \
    XDG_CONFIG_HOME=/tmp/caddy-config
USER 65532:65532

EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
