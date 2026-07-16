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

// Pure unit tests for route rendering and admin URL resolution.

import (
	"encoding/json"
	"strings"
	"testing"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
)

func TestRenderRoute(t *testing.T) {
	site := &gatewayv1alpha1.CaddySite{
		ObjectMeta: metav1.ObjectMeta{Name: "clubhouse", Namespace: "default"},
		Spec: gatewayv1alpha1.CaddySiteSpec{
			CaddyRef: "edge",
			Hosts:    []string{"demo.example.com", "www.example.com"},
			Routes: []gatewayv1alpha1.CaddySiteRoute{
				{Path: "/", Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: "clubhouse", Port: 8080}},
			},
		},
	}

	route := renderRoute(site)

	if route.ID != "kaddy.default.clubhouse" {
		t.Fatalf("route id: want kaddy.default.clubhouse, got %q", route.ID)
	}

	// Serialize once so assertions hit the wire format the admin API sees.
	raw, err := json.Marshal(route.Body)
	if err != nil {
		t.Fatalf("marshal route body: %v", err)
	}
	body := string(raw)

	for _, want := range []string{
		`"host":["demo.example.com","www.example.com"]`,
		`"path":["/*"]`,
		`"dial":"clubhouse.default.svc.cluster.local:8080"`,
		`"handler":"reverse_proxy"`,
		`"terminal":true`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("rendered route missing %s\nbody: %s", want, body)
		}
	}
	if strings.Contains(body, "@id") {
		t.Errorf("renderRoute must not set @id itself (the client injects it): %s", body)
	}
}

func TestDefaultAdminURL(t *testing.T) {
	cases := []struct {
		name   string
		listen string
		want   string
	}{
		{"default port for empty listen", "", "http://edge-admin.default.svc:2019"},
		{"port parsed from listen", ":2020", "http://edge-admin.default.svc:2020"},
		{"host:port listen", "0.0.0.0:9999", "http://edge-admin.default.svc:9999"},
		{"garbage falls back to default", ":not-a-port", "http://edge-admin.default.svc:2019"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			caddy := &gatewayv1alpha1.Caddy{
				ObjectMeta: metav1.ObjectMeta{Name: "edge", Namespace: "default"},
				Spec:       gatewayv1alpha1.CaddySpec{Admin: gatewayv1alpha1.CaddyAdmin{Listen: tc.listen}},
			}
			if got := DefaultAdminURL(caddy); got != tc.want {
				t.Fatalf("DefaultAdminURL(%q): want %s, got %s", tc.listen, tc.want, got)
			}
		})
	}
}
