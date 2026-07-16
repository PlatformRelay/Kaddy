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

// ARCH-9 self-heal, two halves:
//   - a Caddy change enqueues exactly the CaddySites that reference it (so a
//     late-appearing/updated caddyRef heals dependent sites at once instead of
//     waiting for the 30s missingRefRequeue) — TestCaddySitesForCaddy.
//   - a reconcile recreates a deleted owned observability CR (the payload the
//     Owns() watch triggers on external deletion/drift) — TestReconcile_Recreates.
// The Owns()/Watches builder wiring itself is only smoke-covered by setup_test.go
// (SetupWithManager builds without error); these tests cover the *behaviour*.

import (
	"context"
	"testing"
	"time"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin/admintest"
)

const (
	siteMatch = "site-match"
	siteHeal  = "site-heal"
)

func TestCaddySitesForCaddy_EnqueuesOnlyReferencingSites(t *testing.T) {
	c := startPlainEnv(t)
	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: "web-a", Namespace: testNS},
		Spec:       gatewayv1alpha1.CaddySpec{},
	}
	if err := c.Create(tctx, caddy); err != nil {
		t.Fatalf("create Caddy: %v", err)
	}

	// One site references web-a; another references a different Caddy.
	match := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: siteMatch, Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: "web-a",
			Hosts:    []string{testHost},
			Routes:   []gatewayv1alpha1.CaddySiteRoute{{Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: siteMatch, Port: 8080}}},
		},
	}
	other := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: "site-other", Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: "web-b",
			Hosts:    []string{testHost},
			Routes:   []gatewayv1alpha1.CaddySiteRoute{{Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: "site-other", Port: 8080}}},
		},
	}
	for _, s := range []*gatewayv1alpha1.CaddySite{match, other} {
		if err := c.Create(tctx, s); err != nil {
			t.Fatalf("create CaddySite %s: %v", s.Name, err)
		}
	}

	r := &CaddySiteReconciler{Client: c, Scheme: c.Scheme()}
	reqs := r.caddySitesForCaddy(tctx, caddy)

	if len(reqs) != 1 {
		t.Fatalf("want exactly 1 enqueued request, got %d: %v", len(reqs), reqs)
	}
	if reqs[0].Name != siteMatch || reqs[0].Namespace != testNS {
		t.Errorf("enqueued the wrong site: got %s/%s, want %s/%s", reqs[0].Namespace, reqs[0].Name, testNS, siteMatch)
	}
}

// TestReconcile_RecreatesDeletedServiceMonitor proves the self-heal payload:
// after an owned ServiceMonitor is externally deleted, a reconcile (the event
// the Owns() watch enqueues) recreates it. Guards against a silent regression
// where reconcile stops re-ensuring the observability CRs.
func TestReconcile_RecreatesDeletedServiceMonitor(t *testing.T) {
	c := startPlainEnv(t)
	admin := admintest.NewServer()
	t.Cleanup(admin.Close)
	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: "web-heal", Namespace: testNS},
		Spec:       gatewayv1alpha1.CaddySpec{},
	}
	if err := c.Create(tctx, caddy); err != nil {
		t.Fatalf("create Caddy: %v", err)
	}
	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: siteHeal, Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef:      "web-heal",
			Hosts:         []string{testHost},
			Routes:        []gatewayv1alpha1.CaddySiteRoute{{Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: siteHeal, Port: 8080}}},
			Observability: gatewayv1alpha1.CaddySiteObservability{ServiceMonitor: true},
		},
	}
	if err := c.Create(tctx, site); err != nil {
		t.Fatalf("create CaddySite: %v", err)
	}

	r := &CaddySiteReconciler{Client: c, Scheme: c.Scheme(), AdminURL: func(*gatewayv1alpha1.Caddy) string { return admin.URL() }}
	key := types.NamespacedName{Namespace: testNS, Name: siteHeal}

	// First reconciles create the ServiceMonitor (finalizer add + upsert + ensure).
	for i := range 2 {
		if _, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
			t.Fatalf("reconcile #%d: %v", i+1, err)
		}
	}
	sm := &unstructured.Unstructured{}
	sm.SetGroupVersionKind(serviceMonitorGVK)
	if err := c.Get(tctx, key, sm); err != nil {
		t.Fatalf("ServiceMonitor not created by initial reconcile: %v", err)
	}

	// Simulate external deletion/drift — what the Owns() watch reacts to.
	if err := c.Delete(tctx, sm); err != nil {
		t.Fatalf("delete ServiceMonitor: %v", err)
	}
	gone := &unstructured.Unstructured{}
	gone.SetGroupVersionKind(serviceMonitorGVK)
	if err := c.Get(tctx, key, gone); !apierrors.IsNotFound(err) {
		t.Fatalf("expected ServiceMonitor deleted, got err=%v", err)
	}

	// The reconcile the Owns() watch would enqueue must recreate it.
	if _, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
		t.Fatalf("reconcile after delete: %v", err)
	}
	healed := &unstructured.Unstructured{}
	healed.SetGroupVersionKind(serviceMonitorGVK)
	if err := c.Get(tctx, key, healed); err != nil {
		t.Errorf("ServiceMonitor not recreated after reconcile (self-heal failed): %v", err)
	}
}
