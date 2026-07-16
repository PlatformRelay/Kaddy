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

// E9-S01 API-shape and validation tests (TDD).
//
// REQ-E9-S01-01: CRD `Caddy` in gateway.kaddy.io/v1alpha1 — CRD is Established.
// Plus the schema contract from openspec/changes/e9-caddy-operator/design.md:
// defaults (replicas, admin.listen, gatewayClassName, metrics.enabled, route path)
// and validation (replicas >= 0, caddyRef/hosts non-empty, port 1-65535).

import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"

	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/utils/ptr"
	"sigs.k8s.io/controller-runtime/pkg/client"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
)

var _ = Describe("E9-S01 API shape", func() {
	const ns = "default"

	crdIsEstablished := func(name string) {
		GinkgoHelper()
		crd := &apiextensionsv1.CustomResourceDefinition{}
		Expect(k8sClient.Get(ctx, types.NamespacedName{Name: name}, crd)).To(Succeed())
		for _, cond := range crd.Status.Conditions {
			if cond.Type == apiextensionsv1.Established {
				Expect(cond.Status).To(Equal(apiextensionsv1.ConditionTrue),
					"CRD %s should be Established", name)
				return
			}
		}
		Fail("CRD " + name + " has no Established condition")
	}

	Context("REQ-E9-S01-01: API group version", func() {
		It("establishes caddies.gateway.kaddy.io", func() {
			crdIsEstablished("caddies.gateway.kaddy.io")
		})

		It("establishes caddysites.gateway.kaddy.io", func() {
			crdIsEstablished("caddysites.gateway.kaddy.io")
		})
	})

	Context("Caddy defaulting", func() {
		It("fills spec defaults on a minimal Caddy", func() {
			caddy := &gatewayv1alpha1.Caddy{
				ObjectMeta: metav1.ObjectMeta{Name: "e9s01-caddy-defaults", Namespace: ns},
			}
			Expect(k8sClient.Create(ctx, caddy)).To(Succeed())
			DeferCleanup(func() { _ = k8sClient.Delete(ctx, caddy) })

			fetched := &gatewayv1alpha1.Caddy{}
			Expect(k8sClient.Get(ctx, client.ObjectKeyFromObject(caddy), fetched)).To(Succeed())
			Expect(fetched.Spec.Replicas).To(HaveValue(BeEquivalentTo(1)), "replicas should default to 1")
			Expect(fetched.Spec.GatewayClassName).To(Equal("caddy"), "gatewayClassName should default to caddy")
			Expect(fetched.Spec.Admin.Listen).To(Equal(":2019"), `admin.listen should default to ":2019"`)
			Expect(fetched.Spec.Metrics.Enabled).To(HaveValue(BeTrue()), "metrics.enabled should default to true")
		})
	})

	Context("Caddy validation", func() {
		It("rejects negative replicas", func() {
			caddy := &gatewayv1alpha1.Caddy{
				ObjectMeta: metav1.ObjectMeta{Name: "e9s01-caddy-negative", Namespace: ns},
				Spec:       gatewayv1alpha1.CaddySpec{Replicas: ptr.To(int32(-1))},
			}
			err := k8sClient.Create(ctx, caddy)
			Expect(apierrors.IsInvalid(err)).To(BeTrue(), "negative replicas must be Invalid, got: %v", err)
		})
	})

	Context("CaddySite validation", func() {
		validSite := func(name string) *gatewayv1alpha1.CaddySite {
			return &gatewayv1alpha1.CaddySite{
				ObjectMeta: metav1.ObjectMeta{Name: name, Namespace: ns},
				Spec: gatewayv1alpha1.CaddySiteSpec{
					CaddyRef: "edge",
					Hosts:    []string{"demo.example.com"},
					Routes: []gatewayv1alpha1.CaddySiteRoute{
						{Backend: gatewayv1alpha1.CaddySiteBackend{ServiceName: "clubhouse", Port: 8080}},
					},
				},
			}
		}

		It("accepts the design.md sample and defaults route path to /", func() {
			site := validSite("e9s01-site-valid")
			site.Spec.Observability = gatewayv1alpha1.CaddySiteObservability{
				PrometheusRules: true, ServiceMonitor: true, GrafanaDashboard: true,
			}
			Expect(k8sClient.Create(ctx, site)).To(Succeed())
			DeferCleanup(func() { _ = k8sClient.Delete(ctx, site) })

			fetched := &gatewayv1alpha1.CaddySite{}
			Expect(k8sClient.Get(ctx, client.ObjectKeyFromObject(site), fetched)).To(Succeed())
			Expect(fetched.Spec.Routes).To(HaveLen(1))
			Expect(fetched.Spec.Routes[0].Path).To(Equal("/"), "route path should default to /")
		})

		It("rejects an empty caddyRef", func() {
			site := validSite("e9s01-site-nocaddyref")
			site.Spec.CaddyRef = ""
			err := k8sClient.Create(ctx, site)
			Expect(apierrors.IsInvalid(err)).To(BeTrue(), "empty caddyRef must be Invalid, got: %v", err)
		})

		It("rejects empty hosts", func() {
			site := validSite("e9s01-site-nohosts")
			site.Spec.Hosts = []string{}
			err := k8sClient.Create(ctx, site)
			Expect(apierrors.IsInvalid(err)).To(BeTrue(), "empty hosts must be Invalid, got: %v", err)
		})

		It("rejects an out-of-range backend port", func() {
			for _, port := range []int32{0, 70000} {
				site := validSite("e9s01-site-badport")
				site.Spec.Routes[0].Backend.Port = port
				err := k8sClient.Create(ctx, site)
				Expect(apierrors.IsInvalid(err)).To(BeTrue(), "port %d must be Invalid, got: %v", port, err)
			}
		})

		It("rejects a route without a backend serviceName", func() {
			site := validSite("e9s01-site-nosvc")
			site.Spec.Routes[0].Backend.ServiceName = ""
			err := k8sClient.Create(ctx, site)
			Expect(apierrors.IsInvalid(err)).To(BeTrue(), "empty serviceName must be Invalid, got: %v", err)
		})
	})
})
