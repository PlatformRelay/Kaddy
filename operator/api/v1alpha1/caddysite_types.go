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

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

// CaddySiteBackend points a route at a Kubernetes Service.
type CaddySiteBackend struct {
	// serviceName is the target Service in the CaddySite's namespace.
	ServiceName string `json:"serviceName"`

	// port is the target Service port.
	Port int32 `json:"port"`
}

// CaddySiteRoute binds a path to a backend Service.
type CaddySiteRoute struct {
	// path is the HTTP path prefix to match.
	// +optional
	Path string `json:"path,omitempty"`

	// backend is the Service this route forwards to.
	Backend CaddySiteBackend `json:"backend"`
}

// CaddySiteObservability toggles the per-site observability bundle.
type CaddySiteObservability struct {
	// prometheusRules creates alert rules (error rate, latency, down) for the site.
	// +optional
	PrometheusRules bool `json:"prometheusRules,omitempty"`

	// serviceMonitor creates a ServiceMonitor scraping Caddy metrics for the site.
	// +optional
	ServiceMonitor bool `json:"serviceMonitor,omitempty"`

	// grafanaDashboard creates a Grafana dashboard ConfigMap for the site.
	// +optional
	GrafanaDashboard bool `json:"grafanaDashboard,omitempty"`
}

// CaddySiteSpec defines the desired state of CaddySite — a hostname/path
// binding onto a Caddy dataplane, with an optional observability bundle.
type CaddySiteSpec struct {
	// caddyRef names the Caddy resource (same namespace) that serves this site.
	CaddyRef string `json:"caddyRef"`

	// hosts are the hostnames this site serves.
	Hosts []string `json:"hosts"`

	// routes bind paths to backend Services.
	// +optional
	Routes []CaddySiteRoute `json:"routes,omitempty"`

	// observability toggles the per-site observability bundle.
	// +optional
	Observability CaddySiteObservability `json:"observability,omitempty"`
}

// CaddySiteStatus defines the observed state of CaddySite.
type CaddySiteStatus struct {
	// conditions represent the current state of the CaddySite resource
	// (e.g. Ready, Configured).
	// +listType=map
	// +listMapKey=type
	// +optional
	Conditions []metav1.Condition `json:"conditions,omitempty"`

	// observedGeneration is the generation last acted on by the operator.
	// +optional
	ObservedGeneration int64 `json:"observedGeneration,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

// CaddySite is the Schema for the caddysites API
type CaddySite struct {
	metav1.TypeMeta `json:",inline"`

	// metadata is a standard object metadata
	// +optional
	metav1.ObjectMeta `json:"metadata,omitzero"`

	// spec defines the desired state of CaddySite
	// +required
	Spec CaddySiteSpec `json:"spec"`

	// status defines the observed state of CaddySite
	// +optional
	Status CaddySiteStatus `json:"status,omitzero"`
}

// +kubebuilder:object:root=true

// CaddySiteList contains a list of CaddySite
type CaddySiteList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitzero"`
	Items           []CaddySite `json:"items"`
}

func init() {
	SchemeBuilder.Register(func(s *runtime.Scheme) error {
		s.AddKnownTypes(SchemeGroupVersion, &CaddySite{}, &CaddySiteList{})
		return nil
	})
}
