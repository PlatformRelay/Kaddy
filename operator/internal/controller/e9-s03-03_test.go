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

// REQ-E9-S03-03: Admin API 503 → Ready=False reason AdminAPIUnavailable.
// Behaviour is also covered for Caddy in e9-s02-01_test.go; this aliases the
// same contract onto CaddySite (the site reconciler path).

import (
	"context"
	"testing"
	"time"

	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin/admintest"
)

func TestCaddySite_AdminAPIUnavailable(t *testing.T) {
	c := startPlainEnv(t)
	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	admin := admintest.NewServer()
	t.Cleanup(admin.Close)
	admin.SetUnavailable(true)

	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: testCaddyName, Namespace: testNS},
	}
	if err := c.Create(tctx, caddy); err != nil {
		t.Fatalf("create Caddy: %v", err)
	}

	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: testSiteName, Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: testCaddyName,
			Hosts:    []string{testHost},
			Routes: []gatewayv1alpha1.CaddySiteRoute{{
				Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: testSiteName, Port: 8080},
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
	key := types.NamespacedName{Namespace: testNS, Name: testSiteName}
	for i := range 2 {
		if _, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
			t.Fatalf("reconcile #%d must not error on AdminAPIUnavailable: %v", i+1, err)
		}
	}

	fetched := &gatewayv1alpha1.CaddySite{}
	if err := c.Get(tctx, key, fetched); err != nil {
		t.Fatalf("get CaddySite: %v", err)
	}
	cond := meta.FindStatusCondition(fetched.Status.Conditions, "Ready")
	if cond == nil || cond.Status != metav1.ConditionFalse || cond.Reason != reasonAdminAPIUnavailable {
		t.Fatalf("want Ready=False reason %s, got %+v", reasonAdminAPIUnavailable, cond)
	}
}
