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

// REQ-E9-S02-02: Given a CaddySite whose route carries an `@id`, reconciling
// twice must result in a PATCH (strict replace) to the same `@id` — not
// duplicate POST-appended or PUT-inserted routes (Caddy admin API: POST
// appends to arrays, PUT inserts, PATCH replaces).
// Verified against the fake Admin server's request log.

import (
	"context"
	"net/http"
	"testing"
	"time"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin/admintest"
)

func TestCaddySite_AdminUpsert_Idempotent(t *testing.T) {
	c := startPlainEnv(t)

	admin := admintest.NewServer()
	t.Cleanup(admin.Close)

	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: testCaddyName, Namespace: testNS},
		Spec:       gatewayv1alpha1.CaddySpec{},
	}
	if err := c.Create(tctx, caddy); err != nil {
		t.Fatalf("create Caddy: %v", err)
	}

	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: testSiteName, Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: testCaddyName,
			Hosts:    []string{testHost},
			Routes: []gatewayv1alpha1.CaddySiteRoute{
				{Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: testSiteName, Port: 8080}},
			},
		},
	}
	if err := c.Create(tctx, site); err != nil {
		t.Fatalf("create CaddySite: %v", err)
	}

	r := &CaddySiteReconciler{
		Client:   c,
		Scheme:   c.Scheme(),
		AdminURL: func(*gatewayv1alpha1.Caddy) string { return admin.URL() },
	}
	key := types.NamespacedName{Name: testSiteName, Namespace: testNS}
	req := reconcile.Request{NamespacedName: key}

	// Reconcile twice (plus once more for the finalizer add pass).
	for i := range 3 {
		if _, err := r.Reconcile(tctx, req); err != nil {
			t.Fatalf("reconcile #%d: %v", i+1, err)
		}
	}

	const wantID = "kaddy.default.clubhouse"

	if got := admin.RouteCount(); got != 1 {
		t.Fatalf("routes installed after repeated reconciles: want exactly 1, got %d (duplicates piled up)", got)
	}
	if _, ok := admin.Route(wantID); !ok {
		t.Fatalf("route not stored under stable @id %q", wantID)
	}

	posts, patches := 0, 0
	for _, rec := range admin.Requests() {
		switch rec.Method {
		case http.MethodPost:
			posts++
			if got, _ := rec.Body["@id"].(string); got != wantID {
				t.Fatalf("POSTed route @id: want %q, got %q", wantID, got)
			}
		case http.MethodPut:
			t.Fatalf("PUT %s observed: PUT inserts in the Caddy admin API and would duplicate the route", rec.Path)
		case http.MethodPatch:
			patches++
			if rec.Path != "/id/"+wantID {
				t.Fatalf("PATCH to unexpected path %s, want /id/%s", rec.Path, wantID)
			}
		}
	}
	if posts != 1 {
		t.Fatalf("POST count across reconciles: want exactly 1 create, got %d", posts)
	}
	if patches < 2 {
		t.Fatalf("PATCH count across reconciles: want >=2 strict replaces, got %d", patches)
	}

	fetched := &gatewayv1alpha1.CaddySite{}
	if err := c.Get(tctx, key, fetched); err != nil {
		t.Fatalf("get CaddySite: %v", err)
	}
	if !meta.IsStatusConditionTrue(fetched.Status.Conditions, "Ready") {
		t.Fatalf("CaddySite Ready should be True after successful upsert; conditions: %+v",
			fetched.Status.Conditions)
	}
	if fetched.Status.ObservedGeneration != fetched.Generation {
		t.Fatalf("observedGeneration: want %d, got %d",
			fetched.Generation, fetched.Status.ObservedGeneration)
	}

	// Graceful drain: deleting the site removes the route from the
	// dataplane and releases the finalizer.
	if err := c.Delete(tctx, fetched); err != nil {
		t.Fatalf("delete CaddySite: %v", err)
	}
	if _, err := r.Reconcile(tctx, req); err != nil {
		t.Fatalf("reconcile deletion: %v", err)
	}
	if got := admin.RouteCount(); got != 0 {
		t.Fatalf("route must be drained on deletion, %d left", got)
	}
	if err := c.Get(tctx, key, fetched); !apierrors.IsNotFound(err) {
		t.Fatalf("CaddySite should be gone after finalizer release, got %v", err)
	}
}

func TestCaddySite_CaddyRefNotFound(t *testing.T) {
	c := startPlainEnv(t)

	admin := admintest.NewServer()
	t.Cleanup(admin.Close)

	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: "orphan", Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: "missing",
			Hosts:    []string{testHost},
		},
	}
	if err := c.Create(tctx, site); err != nil {
		t.Fatalf("create CaddySite: %v", err)
	}

	r := &CaddySiteReconciler{
		Client:   c,
		Scheme:   c.Scheme(),
		AdminURL: func(*gatewayv1alpha1.Caddy) string { return admin.URL() },
	}
	key := types.NamespacedName{Name: "orphan", Namespace: testNS}

	// Terminal-ish config error: no reconcile error (no hot-loop), Ready=False,
	// but retry IS scheduled (RequeueAfter > 0) so a later caddyRef fix is seen.
	for i := range 2 {
		res, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key})
		if err != nil {
			t.Fatalf("reconcile #%d with missing caddyRef must not error: %v", i+1, err)
		}
		if res.RequeueAfter <= 0 {
			t.Fatalf("reconcile #%d: want RequeueAfter > 0 for missing caddyRef, got %+v", i+1, res)
		}
	}

	fetched := &gatewayv1alpha1.CaddySite{}
	if err := c.Get(tctx, key, fetched); err != nil {
		t.Fatalf("get CaddySite: %v", err)
	}
	cond := meta.FindStatusCondition(fetched.Status.Conditions, "Ready")
	if cond == nil || cond.Status != metav1.ConditionFalse || cond.Reason != "CaddyRefNotFound" {
		t.Fatalf("want Ready=False reason CaddyRefNotFound, got %+v", cond)
	}
	if got := admin.RouteCount(); got != 0 {
		t.Fatalf("no route may be installed without a resolvable caddyRef, got %d", got)
	}
}
