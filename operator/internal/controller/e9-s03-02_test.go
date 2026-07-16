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

// REQ-E9-S03-02: observability.prometheusRules:true creates a PrometheusRule
// with alert HighHTTPErrorRate and a service label taken from the site.

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

func TestCaddySite_PrometheusRuleHighHTTPErrorRate(t *testing.T) {
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
			Observability: gatewayv1alpha1.CaddySiteObservability{PrometheusRules: true},
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
	for i := range 3 {
		if _, err := r.Reconcile(tctx, reconcile.Request{NamespacedName: key}); err != nil {
			t.Fatalf("reconcile #%d: %v", i+1, err)
		}
	}

	rule := &unstructured.Unstructured{}
	rule.SetGroupVersionKind(prometheusRuleGVK)
	if err := c.Get(tctx, key, rule); err != nil {
		t.Fatalf("get generated PrometheusRule: %v", err)
	}
	if got := rule.GetLabels()[labelKeyService]; got != testSiteName {
		t.Errorf("PrometheusRule metadata label service: want %q, got %q", testSiteName, got)
	}
	if got := rule.GetLabels()[labelKeyPartOf]; got != labelValuePartOf {
		t.Errorf("PrometheusRule metadata label part-of: want %s, got %q", labelValuePartOf, got)
	}

	foundAlert, foundServiceLabel := false, false
	groups, _, _ := unstructured.NestedSlice(rule.Object, "spec", "groups")
	for _, g := range groups {
		gm, ok := g.(map[string]any)
		if !ok {
			continue
		}
		rules, _, _ := unstructured.NestedSlice(gm, "rules")
		for _, rr := range rules {
			rm, ok := rr.(map[string]any)
			if !ok {
				continue
			}
			if rm["alert"] == "HighHTTPErrorRate" {
				foundAlert = true
				labels, _, _ := unstructured.NestedStringMap(rm, "labels")
				if labels[labelKeyService] == testSiteName {
					foundServiceLabel = true
				}
			}
		}
	}
	if !foundAlert {
		t.Fatalf("PrometheusRule missing alert HighHTTPErrorRate; groups=%v", groups)
	}
	if !foundServiceLabel {
		t.Fatalf("HighHTTPErrorRate alert missing labels.service=%q", testSiteName)
	}
}
