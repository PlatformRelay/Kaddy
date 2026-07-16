# Spec — E-Caddy-MVP · Showcase content (the demo site serves the Kaddy story)

Epic: `e-caddy-mvp` · **Refs:** exercise brief (install Caddy, serve a page, scrape, alert); D-030
(showcase content + nginx→Caddy topology) · ADR-0104 (edge = Cilium Gateway, not Caddy) · D-019 · D-026

> **Design-first / gated.** Same gating as the parent `caddy-mvp` spec (E1 → E3 → E4; E7 for Rollouts).
> These REQs record the operator's decision (D-030) that the served-website tenant **serves the Kaddy
> project's own Slidev deck + MkDocs docs** — the demo site *is* the pitch — via a deliberate
> **nginx (reverse proxy) → Caddy (static origin)** topology that also gives the parked `caddy_*`
> marshal alerts a real scrape target. Level tags per ADR-0701.

---

## REQ-CADDY-S05-01: Site content is the Kaddy deck + docs (self-referential demo)

**Priority:** should · **Level:** L2 · **Refs:** D-030, E12 (deck), mkdocs.yml  
**Given** the `clubhouse` tenant site  
**When** it is served through the platform edge  
**Then** it serves the built **Slidev deck** (`slides/`, E12) at `/slides/` and the built **MkDocs
Material** docs (`docs/`, `mkdocs.yml`) at `/docs/`, behind a landing page — not placeholder content  
**Test:** `tests/chainsaw/caddy-mvp/showcase/content-served/chainsaw-test.yaml`

**Verify:**
```bash
curl -sf http://127.0.0.1:30080/docs/ | grep -qi 'kaddy' && \
curl -sf http://127.0.0.1:30080/slides/ | grep -qi 'kaddy'
```

---

## REQ-CADDY-S05-02: Content baked into an immutable image (multi-stage build)

**Priority:** should · **Level:** L1 · **Refs:** D-030, ADR-0701 (L1), E11 (scannable image)  
**Given** the tenant image Dockerfile  
**When** it builds  
**Then** a multi-stage build renders `slidev build` + `mkdocs build` and copies the **static** output
into the Caddy image — no build toolchain in the runtime layer, immutable + version-pinned + scannable  
**Test:** `tests/deck/showcase-image-build.sh`

**Verify:**
```bash
# multi-stage: builder stage produces static assets, runtime is caddy:* with no node/python
grep -qE '^FROM .* AS build' deploy/showcase/Dockerfile && \
grep -qE '^FROM (caddy|nginx)' deploy/showcase/Dockerfile
```

---

## REQ-CADDY-S05-03: nginx reverse-proxy → Caddy origin topology

**Priority:** should · **Level:** L2 · **Refs:** exercise "optional nginx reverse proxy", D-030  
**Given** the two-engine topology `Cilium Gateway (TLS) → nginx (reverse proxy) → Caddy (static origin)`  
**When** a request traverses the edge  
**Then** nginx proxies to the Caddy origin Service and Caddy serves the static content; both pods run and
are scraped — turning "Caddy vs nginx" into a designed comparison, not two unrelated pods  
**Test:** `tests/chainsaw/caddy-mvp/showcase/proxy-topology/chainsaw-test.yaml`

**Verify:**
```bash
kubectl get rollouts.argoproj.io -n caddy-mvp nginx-proxy caddy-origin \
  -o jsonpath='{.items[*].status.availableReplicas}' | grep -qE '1 1|[1-9] [1-9]'
```

---

## REQ-CADDY-S05-04: Caddy origin exposes /metrics — revives the parked caddy_* alerts

**Priority:** should · **Level:** L1 · **Refs:** D-026 (parked alerts), ARCH-2/ARCH-3, D-030  
**Given** the Caddy origin with `metrics` enabled and the parked E5 `caddy_*` marshal PrometheusRules  
**When** in-cluster Prometheus scrapes the Caddy origin `/metrics` and the promtool suite runs  
**Then** `caddy_*` metrics are emitted by a **real** target (not a synthetic edge), and each parked
alert **fires** when its condition holds and is **silent** otherwise (fire + silent preserved) — closing
the D-026 loop (the alerts now have the tenant target they were parked to await)  
**Test:** `tests/promtool/caddy-mvp-showcase.test.yaml`

**Verify:**
```bash
promtool test rules tests/promtool/caddy-mvp-showcase.test.yaml
```

---

## REQ-CADDY-S05-05: STRETCH — second tenant proves WebsiteClaim.spec.source (BYO git)

**Priority:** may · **Level:** L2 · **Refs:** E6 (`Website` XR `source`), stretch  
**Given** a second `Website` XR whose `spec.source` points at an external git repo/path  
**When** it reconciles  
**Then** the platform serves that repo's content — proving the platform API's `source` field, i.e.
"tenants bring their own git repo; the platform serves it" (the showcase tenant bakes content; this one
pulls it)  
**Test:** `tests/chainsaw/caddy-mvp/showcase/byo-source/chainsaw-test.yaml`

**Verify:**
```bash
kubectl get website -n byo-demo -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' | grep -q True
```

---

## Note — relationship to E12 and E10

- **E12** owns the *deck itself* (Slidev speaker notes + iframes + video). This spec only requires the
  deck's **build output** be served as tenant content; the deck's authoring lives in E12.
- **E10** (portal, cuttable) can scaffold this showcase tenant via the auto-generated `Website` form,
  but the showcase works via GitOps even if E10 is cut — consistent with the parent epic's stance.
