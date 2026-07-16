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

// ARCH-9: a Caddy change must enqueue exactly the CaddySites that reference it,
// so a late-appearing/updated caddyRef heals dependent sites at once instead of
// waiting for the 30s missingRefRequeue. (The SetupWithManager wiring that
// installs this watch — plus Owns on the observability CRs — is covered by the
// existing SetupWithManager spec in setup_test.go.)

import (
	"context"
	"testing"
	"time"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
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
		ObjectMeta: metav1.ObjectMeta{Name: "site-match", Namespace: testNS},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: "web-a",
			Hosts:    []string{testHost},
			Routes:   []gatewayv1alpha1.CaddySiteRoute{{Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: "site-match", Port: 8080}}},
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
	if reqs[0].Name != "site-match" || reqs[0].Namespace != testNS {
		t.Errorf("enqueued the wrong site: got %s/%s, want %s/site-match", reqs[0].Namespace, reqs[0].Name, testNS)
	}
}
