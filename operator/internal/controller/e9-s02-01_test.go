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

// REQ-E9-S02-01: Given a valid Caddy spec and a reachable Admin API mock,
// the reconciler sets status condition Ready=True within 3 reconcile loops.
// Verify: go test ./internal/controller/... -run TestCaddy_Reconcile_Ready

import (
	"context"
	"testing"
	"time"

	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/utils/ptr"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin/admintest"
)

func TestCaddy_Reconcile_Ready(t *testing.T) {
	c := startPlainEnv(t)

	admin := admintest.NewServer()
	t.Cleanup(admin.Close)

	tctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	t.Cleanup(cancel)

	caddy := &gatewayv1alpha1.Caddy{
		ObjectMeta: metav1.ObjectMeta{Name: testCaddyName, Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySpec{
			Replicas:         ptr.To(int32(2)),
			GatewayClassName: "caddy",
		},
	}
	if err := c.Create(tctx, caddy); err != nil {
		t.Fatalf("create Caddy: %v", err)
	}

	r := &CaddyReconciler{
		Client:   c,
		Scheme:   c.Scheme(),
		AdminURL: func(*gatewayv1alpha1.Caddy) string { return admin.URL() },
	}
	key := types.NamespacedName{Name: testCaddyName, Namespace: testNS}
	req := reconcile.Request{NamespacedName: key}

	fetched := &gatewayv1alpha1.Caddy{}
	readyWithin := func(loops int) bool {
		for i := range loops {
			if _, err := r.Reconcile(tctx, req); err != nil {
				t.Fatalf("reconcile #%d: %v", i+1, err)
			}
			if err := c.Get(tctx, key, fetched); err != nil {
				t.Fatalf("get Caddy: %v", err)
			}
			if meta.IsStatusConditionTrue(fetched.Status.Conditions, "Ready") {
				return true
			}
		}
		return false
	}

	if !readyWithin(3) {
		t.Fatalf("Ready condition not True within 3 reconcile loops; conditions: %+v",
			fetched.Status.Conditions)
	}
	if fetched.Status.ObservedGeneration != fetched.Generation {
		t.Fatalf("observedGeneration: want %d, got %d",
			fetched.Generation, fetched.Status.ObservedGeneration)
	}

	// Level-based: when the Admin API goes away, Ready flips to False with
	// reason AdminAPIUnavailable instead of erroring the reconcile loop.
	admin.SetUnavailable(true)
	if _, err := r.Reconcile(tctx, req); err != nil {
		t.Fatalf("reconcile with unavailable admin API must not error (transient): %v", err)
	}
	if err := c.Get(tctx, key, fetched); err != nil {
		t.Fatalf("get Caddy: %v", err)
	}
	cond := meta.FindStatusCondition(fetched.Status.Conditions, "Ready")
	if cond == nil || cond.Status != metav1.ConditionFalse || cond.Reason != reasonAdminAPIUnavailable {
		t.Fatalf("want Ready=False reason %s, got %+v", reasonAdminAPIUnavailable, cond)
	}

	// And back: recovery is observed without manual intervention.
	admin.SetUnavailable(false)
	if !readyWithin(3) {
		t.Fatalf("Ready did not recover after Admin API came back; conditions: %+v",
			fetched.Status.Conditions)
	}
}
