# Spec — E8 scorecard evidence

Epic: E8 · ADR: [0202](../../../docs/adr/0202-evidence-as-artifact.md)  
**Refs:** gridscale deliverable (screenshots/logs)  
**Level:** L3 k6 · L4 scorecard HTML · meta docs contract + L2 live smoke (S04)

---

## REQ-E8-S01-01: k6 load profile

**Priority:** must  
**Given** `tests/load/marshal-threshold.js`  
**When** `k6 run` with `RATE=150` (above documented threshold)  
**Then** test completes; Prometheus shows elevated request rate  
**Test:** `tests/load/marshal-threshold.js`

**Verify:** `task test:load` exits 0; PromQL `rate(...)` exceeds threshold in output JSON

---

## REQ-E8-S01-02: k6 triggers HighRequestRate alert

**Priority:** must  
**Given** REQ-E5-S03-04 rule active  
**When** k6 profile runs for ≥ 3m  
**Then** Alertmanager shows firing `HighRequestRate`  
**Test:** `tests/smoke/e8-s01-02.sh`
**Verify:**
```bash
curl -s http://127.0.0.1:9093/api/v2/alerts | jq -e '.[] | select(.labels.alertname=="HighRequestRate")'
```

---

## REQ-E8-S02-01: Capture Prometheus snapshots

**Priority:** must  
**Given** `hack/scorecard/capture.sh`  
**When** run after k6  
**Then** `evidence/runs/<date>/prometheus/queries.json` contains up, error rate, latency queries  
**Test:** `tests/smoke/e8-s02-01.sh`

**Verify:** `test -f evidence/runs/*/prometheus/queries.json`

---

## REQ-E8-S02-04: Capture Loki log evidence

**Priority:** should · **ADR:** [0108](../../../docs/adr/0108-logging-loki.md)  
**Given** Loki reachable during capture  
**When** `hack/scorecard/capture.sh` runs a LogQL `query_range` for `{service="caddy"}` 5xx  
**Then** `evidence/runs/<date>/loki/caddy-errors.json` is written  
**Test:** `tests/smoke/e8-s02-04.sh`

**Verify:** `test -f evidence/runs/*/loki/caddy-errors.json`

---

## REQ-E8-S02-02: Capture Alertmanager state

**Priority:** must  
**When** capture runs  
**Then** `evidence/runs/<date>/alertmanager/alerts.json` is non-empty array during alert window  
**Test:** `tests/smoke/e8-s02-02.sh`

**Verify:** `jq 'length' evidence/runs/*/alertmanager/alerts.json` ≥ 1

---

## REQ-E8-S02-03: HTML scorecard report

**Priority:** must  
**Given** template `hack/scorecard/template.html`  
**When** capture completes  
**Then** `evidence/runs/<date>/index.html` renders sections: alerts, metrics, k6, rollout status  
**Test:** `tests/smoke/e8-s02-03.sh`

**Verify:** `test -f evidence/runs/*/index.html && rg 'HighRequestRate' evidence/runs/*/index.html`

---

## REQ-E8-S03-01: GitHub Pages publish

**Priority:** must  
**Given** workflow `.github/workflows/scorecard-pages.yaml`  
**When** merge to main after `task test:scorecard`  
**Then** latest report available at documented Pages URL  
**Test:** `tests/smoke/e8-s03-01.sh`

**Verify:** `curl -s -o /dev/null -w '%{http_code}' https://<pages-url>/` == 200

---

## REQ-E8-S04-01: Reproducible local Getting Started path

**Priority:** must · **Level:** meta  
**Given** a workstation with the documented pinned prerequisites and no `kaddy-dev` cluster  
**When** an operator follows `docs/getting-started.md` from top to bottom  
**Then** the guide creates only the isolated `kind-kaddy-dev` context, bootstraps the platform in
dependency order, waits for the declared readiness conditions, and proves the expected Argo CD
Applications and Website claim healthy without relying on an ambient kubeconfig  
**And** the root README links this guide before the deep architecture path  
**Test:** `tests/meta/e8-s04-getting-started.sh`

**Verify:** `tests/meta/e8-s04-getting-started.sh`

---

## REQ-E8-S04-02: Cost / footprint table

**Priority:** should  
**Given** gridscale resources used (GSK node pools, LBaaS, Object Storage)  
**When** README table populated  
**Then** monthly estimate documented (GSK nodes, LBaaS, storage)  
**Test:** `tests/smoke/e8-s04-02.sh`

**Verify:** `rg 'EUR|monthly' README.md`

---

## REQ-E8-S04-03: Service access catalogue uses honest local access methods

**Priority:** must · **Level:** meta  
**Given** a healthy local platform  
**When** a reviewer opens the Getting Started service catalogue  
**Then** it names each user-visible surface, its purpose, canonical URL or CLI surface, local access
or verification command, authentication source, and whether that path traverses the Cilium Gateway,
including at minimum:

- Argo CD — `https://127.0.0.1:30443/applications`;
- clubhouse — canonical `https://clubhouse.kaddy.local/`, verified through the real TLS edge by
  `task test:smoke:e4`, plus an explicitly labeled direct-backend preview when useful;
- the composed Website demo — canonical `https://clubhouse.kaddy.local/putting-green/`, verified by
  `task test:smoke:e6`;
- Grafana — `http://127.0.0.1:23000/` (`E5_GRAFANA_PORT`, collision-avoiding default) through an
  explicit port-forward;
- Prometheus — `http://127.0.0.1:29090/` through an explicit port-forward; and
- Alertmanager — `http://127.0.0.1:29093/` through an explicit port-forward;
- mulligan — CLI rollout and HTTPRoute observation used by `task demo` and `task demo:chaos`.

**And** the guide derives credentials from Kubernetes Secrets without printing or committing them,
distinguishes fixed kind mappings, direct-backend port-forwards, and real Gateway verification  
**And** it does not instruct macOS users to curl LB-IPAM addresses or port-forward selectorless
Cilium Gateway Services, nor invent browser URLs for API-only surfaces such as Crossplane  
**Test:** `tests/meta/e8-s04-getting-started.sh`

**Verify:** `tests/meta/e8-s04-getting-started.sh`

---

## REQ-E8-S04-04: Demo choreography proves the platform claims

**Priority:** must · **Level:** L2 (live smoke)  
**Given** the readiness checks in REQ-E8-S04-01 pass  
**When** a reviewer follows the demo section  
**Then** it first records a healthy baseline and then runs, in a stated order:

1. the Website claim path (`Website` → composed workload, TLS route, and ServiceMonitor);
2. `task demo:fire` (serve → scrape → `ClubhouseDown` firing in Alertmanager → restore → resolve);
3. `task demo` (blue/green promotion and live canary HTTPRoute weight shifts); and
4. `task demo:chaos` (failed canary abort and stable-weight rollback).

**And** each act states what to show in the terminal or browser, its expected duration, its success
signal, and a shorter fallback path when an optional surface is unavailable  
**Test:** `tests/smoke/e8-s04-demo.sh`

**Verify:** `tests/smoke/e8-s04-demo.sh`

---

## REQ-E8-S04-05: Recovery and teardown leave no hidden state

**Priority:** must · **Level:** meta  
**Given** a demo command fails, is interrupted, or encounters an occupied local port  
**When** the reviewer follows the troubleshooting and cleanup sections  
**Then** the guide provides non-destructive diagnostics, documents port overrides, restores the
clubhouse replica and stable rollout weights, stops temporary port-forwards, and offers
`task cluster:down` as the explicit full teardown  
**And** rerunning the Getting Started path is idempotent  
**Test:** `tests/meta/e8-s04-getting-started.sh`

**Verify:** `tests/meta/e8-s04-getting-started.sh`

---

## REQ-E8-S04-06: Five-minute reviewer path stays honest

**Priority:** must · **Level:** meta  
**Given** the root README and `docs/getting-started.md`  
**When** a reviewer chooses the five-minute path  
**Then** the order is: (1) released demo/deck artifact, (2) scorecard URL when E8-S03 exists,
(3) local service URLs and demo commands, and (4) architecture  
**And** any surface not yet implemented or published is labeled unavailable rather than shown as a
working URL  
**Test:** `tests/meta/e8-s04-getting-started.sh`

**Verify:** `tests/meta/e8-s04-getting-started.sh`

---

## REQ-E8-EXIT: Full scorecard pipeline
**Test:** `hack/scorecard/validate.sh`
**Priority:** must  

**Verify:** `task test:scorecard` produces dated bundle and passes schema check `hack/scorecard/validate.sh`
