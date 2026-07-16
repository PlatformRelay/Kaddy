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

// REQ-E9-S03-01: a successfully reconciled CaddySite requesting a
// ServiceMonitor receives one carrying the ADR-0301 mandatory core labels.

import (
	"context"
	"testing"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin/admintest"
)

func TestCaddySite_ServiceMonitorCreated(t *testing.T) {
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
		ObjectMeta: metav1.ObjectMeta{Name: testSiteName, Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: testCaddyName,
			Hosts:    []string{testHost},
			Routes: []gatewayv1alpha1.CaddySiteRoute{{
				Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: testSiteName, Port: 8080},
			}},
			Observability: gatewayv1alpha1.CaddySiteObservability{ServiceMonitor: true},
		},
	}
	if err := c.Create(tctx, site); err != nil {
		t.Fatalf("create CaddySite: %v", err)
	}

	reconciler := &CaddySiteReconciler{
		Client: c, Scheme: c.Scheme(),
		AdminURL: func(*gatewayv1alpha1.Caddy) string { return admin.URL() },
	}
	key := types.NamespacedName{Namespace: testNS, Name: testSiteName}
	for i := range 3 {
		if _, err := reconciler.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
			t.Fatalf("reconcile #%d: %v", i+1, err)
		}
	}

	monitor := &unstructured.Unstructured{}
	monitor.SetGroupVersionKind(serviceMonitorGVK)
	if err := c.Get(tctx, types.NamespacedName{Namespace: testNS, Name: testSiteName}, monitor); err != nil {
		t.Fatalf("get generated ServiceMonitor: %v", err)
	}

	for key, want := range map[string]string{
		labelKeyOwner:               labelValueOwnerDef,
		labelKeyService:             testSiteName,
		labelKeyPartOf:              labelValuePartOf,
		labelKeyManagedBy:           labelValueManagedBy,
		labelKeyDataClassification:  labelValueClassDef,
		labelKeyBusinessCriticality: labelValueCritDef,
		labelKeyTrack:               labelValueTrackDef,
	} {
		if got := monitor.GetLabels()[key]; got != want {
			t.Errorf("ServiceMonitor label %q: want %q, got %q", key, want, got)
		}
	}
}
