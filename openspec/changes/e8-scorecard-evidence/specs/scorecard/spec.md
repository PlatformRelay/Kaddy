# Spec — E8 scorecard evidence

Epic: E8 · ADR: [0202](../../../docs/adr/0202-evidence-as-artifact.md)  
**Refs:** gridscale deliverable (screenshots/logs)  
**Level:** L3 k6 · L4 scorecard HTML

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
**Test:** `tests/smoke/req-e8-s01-02- k6 triggers highrequestrate alert.sh`
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

## REQ-E8-S04-01: README 5-minute path complete

**Priority:** must  
**Given** root README  
**When** reviewer follows links  
**Then** order is: (1) demo recording, (2) scorecard URL, (3) live URLs, (4) architecture  
**Test:** `tests/meta/e8-s04-01-checklist.md`

**Verify:** manual review checklist in PR template

---

## REQ-E8-S04-02: Cost / footprint table

**Priority:** should  
**Given** gridscale resources used (GSK node pools, LBaaS, Object Storage)  
**When** README table populated  
**Then** monthly estimate documented (GSK nodes, LBaaS, storage)  
**Test:** `tests/smoke/e8-s04-02.sh`

**Verify:** `rg 'EUR|monthly' README.md`

---

## REQ-E8-EXIT: Full scorecard pipeline
**Test:** `hack/scorecard/validate.sh`
**Priority:** must  

**Verify:** `task test:scorecard` produces dated bundle and passes schema check `hack/scorecard/validate.sh`
