# Spec — E3 GitOps platform core

Epic: E3 · ADR: [0103](../../../docs/adr/0103-argocd-gitops.md)

---

## REQ-E3-S01-01: App-of-apps root Application

**Priority:** must  
**Given** `deploy/apps/root.yaml` pointing at `deploy/apps/`  
**When** Argo CD syncs root  
**Then** child Applications appear: `platform-core`, `identity`, `observability`, `gateway`, `workloads`  
**Test:** `tests/smoke/e3-s01-01.sh`

**Verify:** `argocd app list | grep -E 'platform-core|observability'`

---

## REQ-E3-S01-02: Sync policy documented

**Priority:** should  
**Given** lab environment  
**When** auto-sync enabled on non-destructive apps  
**Then** `syncPolicy.automated.selfHeal: true` on the control-plane apps (`root` + `platform-core`) — both manage only declarative Argo/config CRs; workload-facing children (`observability`, `gateway`, `workloads`) keep selfHeal off, `identity` is manual (documented exceptions for stateful/traffic/rollouts)  
**Test:** `tests/smoke/e3-s01-02.sh`

**Verify:** `rg 'selfHeal' deploy/apps/`

---

## REQ-E3-S01-03: KSOPS plugin for SOPS secrets

**Priority:** must · **ADR:** [0110](../../../docs/adr/0110-secrets-sops-age.md) · **Decision:** D-020  
**Given** Argo CD repo-server with KSOPS init container or sidecar  
**When** Application syncs `deploy/secrets/`  
**Then** encrypted manifests decrypt at render time; no manual `kubectl create secret`  
**Test:** `tests/smoke/e3-s01-03.sh`

**Verify:** `rg -i 'ksops|sops' deploy/bootstrap/ deploy/apps/`

---

## REQ-E3-S02-01: Prometheus Operator CRDs

**Priority:** must  
**Given** kube-prometheus-stack synced  
**When** `kubectl get crd servicemonitors.monitoring.coreos.com`  
**Then** CRD Established  
**Test:** `tests/smoke/e3-s02-01.sh`

**Verify:** `kubectl get crd servicemonitors.monitoring.coreos.com`

---

## REQ-E3-S02-02: Prometheus and Alertmanager pods Running

**Priority:** must  
**Given** observability namespace  
**When** `kubectl get pods -n monitoring`  
**Then** prometheus and alertmanager pods Running  
**Test:** `tests/chainsaw/monitoring/stack-ready.yaml`

**Verify:** Chainsaw `tests/chainsaw/monitoring/stack-ready.yaml`

---

## REQ-E3-S02-03: Loki deployed

**Priority:** must · **ADR:** [0108](../../../docs/adr/0108-logging-loki.md)  
**Given** `deploy/observability/loki/` synced by Argo CD  
**When** `kubectl get pods -n monitoring -l app.kubernetes.io/name=loki`  
**Then** Loki pod(s) Ready; mandatory kaddy labels present  
**Test:** `tests/chainsaw/monitoring/loki-ready.yaml`

**Verify:** `kubectl wait -n monitoring --for=condition=Ready pod -l app.kubernetes.io/name=loki --timeout=300s`

---

## REQ-E3-S02-04: Grafana Alloy log collector on every node

**Priority:** must · **ADR:** [0108](../../../docs/adr/0108-logging-loki.md)  
**Given** Alloy DaemonSet in `monitoring`  
**When** `kubectl get ds -n monitoring -l app.kubernetes.io/name=alloy`  
**Then** desired == ready (scheduled on all schedulable nodes)  
**Test:** `tests/chainsaw/monitoring/alloy-daemonset.yaml`

**Verify:** `kubectl rollout status ds -n monitoring -l app.kubernetes.io/name=alloy --timeout=180s`

---

## REQ-E3-S02-05: Loki wired as Grafana datasource

**Priority:** must  
**Given** Grafana datasource provisioning ConfigMap  
**When** Grafana starts  
**Then** a `Loki` datasource exists and is the default logs source  
**Test:** `tests/chainsaw/monitoring/grafana-loki-datasource.yaml`

**Verify:** `kubectl get cm -n monitoring -l grafana_datasource=1 -o yaml | rg -i 'type: loki'`

---

## REQ-E3-S03-00: cert-manager controller installed

**Priority:** must  
**Given** cert-manager Helm/manifest in `deploy/cert-manager/`  
**When** synced by Argo CD  
**Then** `cert-manager`, `cert-manager-webhook`, `cert-manager-cainjector` Deployments Available; CRDs Established  
**Test:** `tests/chainsaw/tls/cert-manager-ready.yaml`

**Verify:** `kubectl wait --for=condition=Available deployment -n cert-manager --all --timeout=300s`

---

## REQ-E3-S03-01: Let's Encrypt staging ClusterIssuer Ready

**Priority:** must  
**Given** `deploy/cert-manager/cluster-issuer-staging.yaml` (ACME staging, HTTP-01 via Gateway)  
**When** `kubectl describe clusterissuer letsencrypt-staging`  
**Then** Ready=True (ACME account registered against staging directory)  
**Test:** `tests/chainsaw/tls/clusterissuer-staging.yaml`

**Verify:** `kubectl get clusterissuer letsencrypt-staging -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep True`

---

## REQ-E3-S03-02: Let's Encrypt production ClusterIssuer Ready

**Priority:** must  
**Given** `deploy/cert-manager/cluster-issuer-prod.yaml` (ACME prod directory; email from non-secret config)  
**When** `kubectl describe clusterissuer letsencrypt-prod`  
**Then** Ready=True; issuer used only by hostnames that have passed staging first (documented)  
**Test:** `tests/chainsaw/tls/clusterissuer-prod.yaml`

**Verify:** `kubectl get clusterissuer letsencrypt-prod -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep True`

---

## REQ-E3-S03-03: ACME HTTP-01 solver routes through Gateway

**Priority:** must · **Depends:** E2 (Gateway)  
**Given** HTTP-01 solver configured for the Gateway API listener  
**When** a Certificate is requested for a lab hostname  
**Then** cert-manager creates a solver HTTPRoute/Service and the challenge path is reachable  
**Test:** `tests/chainsaw/tls/http01-solver-route.yaml`

**Verify:** Chainsaw asserts solver `HTTPRoute` exists during a test Certificate order

---

## REQ-E3-S04-01: Argo Rollouts controller installed

**Priority:** must  
**Given** rollouts manifest  
**When** `kubectl get deployment -n argo-rollouts argo-rollouts`  
**Then** Available  
**Test:** `tests/smoke/e3-s04-01.sh`

**Verify:** `kubectl wait -n argo-rollouts --for=condition=Available deployment/argo-rollouts`

---

## REQ-E3-S04-02: Gateway API traffic router plugin

**Priority:** must · **Depends:** E2 L0  
**Given** Rollouts Gateway API plugin ConfigMap  
**When** Rollout with `trafficRouting.plugins` created (dry-run in E7)  
**Then** plugin config references correct HTTPRoute name  
**Test:** `tests/smoke/e3-s04-02.sh`

**Verify:** `kubectl get configmap -n argo-rollouts | grep gateway`

---

## REQ-E3-EXIT: Chainsaw CI enabled

**Priority:** must  
**Given** E3 complete  
**When** `.github/workflows/chainsaw.yaml` runs on PR  
**Then** kind cluster + `task test:chainsaw` executes (suites may skip until later epics)  
**Test:** `tests/smoke/e3-exit.sh`

**Verify:** CI workflow green on PR touching `deploy/`
