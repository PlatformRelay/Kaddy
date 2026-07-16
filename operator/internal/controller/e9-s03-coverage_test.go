/*
Copyright 2026.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controller

// Coverage + idempotency for the observability upsert path: both toggles on,
// custom ADR labels from the site, and a second reconcile that Updates.

import (
	"context"
	"encoding/json"
	"strings"
	"testing"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin/admintest"
)

func TestCaddySite_ObservabilityBundle_IdempotentUpdate(t *testing.T) {
	c := startPlainEnv(t)
	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	admin := admintest.NewServer()
	t.Cleanup(admin.Close)

	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: testCaddyName, Namespace: testNS},
	}
	if err := c.Create(tctx, caddy); err != nil {
		t.Fatalf("create Caddy: %v", err)
	}

	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{
			Name:      testBundleName,
			Namespace: testNS,
			Labels: map[string]string{
				labelKeyOwner:               testSiteOwner,
				labelKeyTrack:               "canary",
				labelKeyDataClassification:  "confidential",
				labelKeyBusinessCriticality: "mission-critical",
			},
		},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: testCaddyName,
			Hosts:    []string{testHost},
			Routes: []gatewayv1alpha1.CaddySiteRoute{{
				Path: "/api", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: testBundleName, Port: 8080},
			}},
			Observability: gatewayv1alpha1.CaddySiteObservability{
				ServiceMonitor:  true,
				PrometheusRules: true,
			},
		},
	}
	if err := c.Create(tctx, site); err != nil {
		t.Fatalf("create CaddySite: %v", err)
	}

	r := &CaddySiteReconciler{
		Client:     c,
		Scheme:     c.Scheme(),
		AdminURL:   func(*gatewayv1alpha1.Caddy) string { return admin.URL() },
		RoutesPath: defaultRoutesPath,
	}
	key := types.NamespacedName{Namespace: testNS, Name: testBundleName}
	for i := range 4 {
		if _, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
			t.Fatalf("reconcile #%d: %v", i+1, err)
		}
	}

	sm := &unstructured.Unstructured{}
	sm.SetGroupVersionKind(serviceMonitorGVK)
	if err := c.Get(tctx, key, sm); err != nil {
		t.Fatalf("get ServiceMonitor: %v", err)
	}
	for key, want := range map[string]string{
		labelKeyOwner:               testSiteOwner,
		labelKeyTrack:               "canary",
		labelKeyDataClassification:  "confidential",
		labelKeyBusinessCriticality: "mission-critical",
		labelKeyService:             testBundleName,
		labelKeyManagedBy:           labelValueManagedBy,
	} {
		if got := sm.GetLabels()[key]; got != want {
			t.Errorf("ServiceMonitor label %q: want %q, got %q", key, want, got)
		}
	}

	pr := &unstructured.Unstructured{}
	pr.SetGroupVersionKind(prometheusRuleGVK)
	if err := c.Get(tctx, key, pr); err != nil {
		t.Fatalf("get PrometheusRule: %v", err)
	}
	if got := pr.GetLabels()[labelKeyOwner]; got != testSiteOwner {
		t.Errorf("PrometheusRule owner label: want %s, got %q", testSiteOwner, got)
	}
}

const (
	testBundleName = "bundle"
	testSiteOwner  = "site-owner"
	testDrainName  = "drain-me"
)

func TestCaddySite_DefaultAdminURLAndRoutesPath(t *testing.T) {
	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: "edge", Namespace: "ns"},
		Spec:       gatewayv1alpha1.CaddySpec{},
	}
	r := &CaddySiteReconciler{Scheme: nil}
	if got := r.adminURL(caddy); got == "" {
		t.Fatal("default adminURL must not be empty")
	}
	if got := r.routesPath(); got != defaultRoutesPath {
		t.Fatalf("routesPath: want %q, got %q", defaultRoutesPath, got)
	}
}

func TestRenderRoute_EmptyPathDefaultsToRoot(t *testing.T) {
	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: "p", Namespace: "ns"},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			Hosts: []string{"h.example"},
			Routes: []gatewayv1alpha1.CaddySiteRoute{{
				Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: "svc", Port: 80},
			}},
		},
	}
	route := renderRoute(site)
	raw, _ := json.Marshal(route.Body)
	if !strings.Contains(string(raw), `"path":["/*"]`) {
		t.Fatalf("empty path must render as /*; body=%s", raw)
	}
}

func TestCaddySite_DrainRetriesWhenAdminUnavailable(t *testing.T) {
	c := startPlainEnv(t)
	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	admin := admintest.NewServer()
	t.Cleanup(admin.Close)

	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: testCaddyName, Namespace: testNS},
	}
	if err := c.Create(tctx, caddy); err != nil {
		t.Fatalf("create Caddy: %v", err)
	}
	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: testDrainName, Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: testCaddyName,
			Hosts:    []string{testHost},
			Routes: []gatewayv1alpha1.CaddySiteRoute{{
				Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: testDrainName, Port: 8080},
			}},
		},
	}
	if err := c.Create(tctx, site); err != nil {
		t.Fatalf("create CaddySite: %v", err)
	}

	r := &CaddySiteReconciler{
		Client: c, Scheme: c.Scheme(),
		AdminURL: func(*gatewayv1alpha1.Caddy) string { return admin.URL() },
	}
	key := types.NamespacedName{Namespace: testNS, Name: testDrainName}
	for i := range 3 {
		if _, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
			t.Fatalf("reconcile #%d: %v", i+1, err)
		}
	}

	fetched := &gatewayv1alpha1.CaddySite{}
	if err := c.Get(tctx, key, fetched); err != nil {
		t.Fatalf("get: %v", err)
	}
	if err := c.Delete(tctx, fetched); err != nil {
		t.Fatalf("delete: %v", err)
	}
	admin.SetUnavailable(true)
	res, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key})
	if err != nil {
		t.Fatalf("drain with unavailable admin must not error: %v", err)
	}
	if res.RequeueAfter <= 0 {
		t.Fatalf("want RequeueAfter during drain unavailable, got %+v", res)
	}

	// caddyRef gone while deleting — finalizer released without drain.
	admin.SetUnavailable(false)
	if err := c.Delete(tctx, caddy); err != nil {
		t.Fatalf("delete Caddy: %v", err)
	}
	if _, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
		t.Fatalf("reconcile after caddy gone: %v", err)
	}
}
