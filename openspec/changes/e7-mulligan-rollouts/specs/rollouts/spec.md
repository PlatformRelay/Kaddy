# Spec — E7 mulligan (progressive delivery)

Epic: E7 · ADR: [0201](../../../docs/adr/0201-rollouts-blue-green-canary.md)  
**Depends:** E2 L0 for canary weights; E5 for AnalysisTemplate metrics

---

## REQ-E7-S01-01: Blue/green Rollout resource

**Priority:** must  
**Given** `deploy/workloads/clubhouse/rollout-bluegreen.yaml`  
**When** applied  
**Then** Rollout uses `blueGreen` strategy with `activeService` and `previewService`  
**Test:** `tests/smoke/e7-s01-01.sh`

**Verify:** `kubectl get rollout clubhouse -o jsonpath='{.spec.strategy.blueGreen}' | jq -e .`

---

## REQ-E7-S01-02: Pre-promotion AnalysisTemplate

**Priority:** must  
**Given** AnalysisTemplate referencing Prometheus error rate  
**When** green version has elevated 5xx (injected)  
**Then** Rollout does **not** promote; `Preview` service only  
**Test:** `tests/chainsaw/rollouts/bluegreen-blocks-bad-promotion.yaml`

**Verify:** Chainsaw `tests/chainsaw/rollouts/bluegreen-blocks-bad-promotion.yaml`

---

## REQ-E7-S01-03: Successful promotion

**Priority:** must  
**Given** green version healthy  
**When** analysis passes  
**Then** active Service selector switches to green; `track: stable` on active pods  
**Test:** `tests/smoke/e7-s01-03.sh`

**Verify:** `kubectl argo rollouts get rollout clubhouse` shows active=green

---

## REQ-E7-S02-01: Canary Rollout with HTTPRoute weights

**Priority:** must · **Depends:** E2-S02-03  
**Given** Rollout with `trafficRouting.plugins` gatewayAPI  
**When** canary steps run 20% → 50%  
**Then** HTTPRoute backend weights match Rollout status  
**Test:** `tests/chainsaw/rollouts/canary-weights.yaml`

**Verify:** Chainsaw `tests/chainsaw/rollouts/canary-weights.yaml`

---

## REQ-E7-S02-02: Analysis fails → rollback (mulligan)

**Priority:** must  
**Given** canary at 50% with failing AnalysisTemplate (error rate)  
**When** analysis run fails  
**Then** weights return to 100% stable; canary ReplicaSet scaled down  
**Test:** `tests/chainsaw/rollouts/canary-rollback.yaml`

**Verify:** Chainsaw `tests/chainsaw/rollouts/canary-rollback.yaml` + Alertmanager `HighHTTPErrorRate`

---

## REQ-E7-S02-03: track label on metrics

**Priority:** must  
**Given** canary pods  
**When** Prometheus query `sum by (track) (rate(http_requests_total[1m]))`  
**Then** series exist for `track=stable` and `track=canary` during rollout  
**Test:** `tests/smoke/e7-s02-03.sh`

**Verify:** PromQL documented; scorecard captures during demo

---

## REQ-E7-S03-01: task demo orchestration

**Priority:** must  
**Given** `hack/demo/mulligan.sh` or Task `demo`  
**When** `task demo` runs  
**Then** script executes blue/green block, canary rollback, captures exit codes for scorecard  
**Test:** `hack/demo/mulligan.sh`

**Verify:** `task demo; echo $?` == 0 on healthy cluster

---

## REQ-E7-S03-02: asciinema recording

**Priority:** should  
**Given** demo script  
**When** recorded  
**Then** `evidence/demo/mulligan.cast` committed or linked from README  
**Test:** `tests/smoke/e7-s03-02.sh`

**Verify:** file exists; README 5-minute path links recording **first** (D-009)

---

## REQ-E7-S04-01: Kill Caddy pod → alert

**Priority:** must  
**Given** marshal rules active  
**When** `kubectl delete pod -n gateway-system -l app.kubernetes.io/name=caddy`  
**Then** `CaddyTargetDown` fires within 3m; pod reschedules  
**Test:** `tests/smoke/e7-s04-01.sh`

**Verify:** Alertmanager API + `kubectl wait` for new pod Ready

---

## REQ-E7-S04-02: Stop nginx VM → legacy path fails

**Priority:** must  
**When** the gridscale nginx server is stopped  
**Then** `/legacy` unhealthy; `/` still 200; Crossplane or manual reconcile documented  
**Test:** `hack/demo/chaos-nginx.sh`

**Verify:** smoke chaos script `hack/demo/chaos-nginx.sh`

---

## REQ-E7-EXIT: Chainsaw rollouts suite green
**Test:** `tests/chainsaw/rollouts`
**Priority:** must  

**Verify:** `chainsaw test tests/chainsaw/rollouts`
