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

// CaddyMetrics configures Prometheus metrics exposure for the Caddy dataplane.
type CaddyMetrics struct {
	// enabled toggles the metrics endpoint and its scrape assets.
	// +kubebuilder:default=true
	// +optional
	Enabled *bool `json:"enabled,omitempty"`
}

// CaddyAdmin configures the Caddy admin API endpoint the operator drives.
type CaddyAdmin struct {
	// listen is the admin API listen address as [host]:port,
	// e.g. ":2019", "0.0.0.0:2019" or "localhost:2019".
	// +kubebuilder:default=":2019"
	// +kubebuilder:validation:Pattern=`^([A-Za-z0-9.\-]+)?:[0-9]{1,5}$`
	// +optional
	Listen string `json:"listen,omitempty"`
}

// CaddySpec defines the desired state of Caddy — the gateway dataplane
// (Deployment, Service, metrics) managed by the kaddy operator.
type CaddySpec struct {
	// replicas is the desired number of Caddy dataplane pods.
	// +kubebuilder:default=1
	// +kubebuilder:validation:Minimum=0
	// +optional
	Replicas *int32 `json:"replicas,omitempty"`

	// gatewayClassName binds this dataplane to a Gateway API GatewayClass.
	// +kubebuilder:default=caddy
	// +kubebuilder:validation:MinLength=1
	// +optional
	GatewayClassName string `json:"gatewayClassName,omitempty"`

	// metrics configures Prometheus metrics exposure.
	// +kubebuilder:default={}
	// +optional
	Metrics CaddyMetrics `json:"metrics,omitempty"`

	// admin configures the Caddy admin API endpoint.
	// +kubebuilder:default={}
	// +optional
	Admin CaddyAdmin `json:"admin,omitempty"`
}

// CaddyStatus defines the observed state of Caddy.
type CaddyStatus struct {
	// conditions represent the current state of the Caddy resource
	// (e.g. Ready, Configured, MetricsAvailable).
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

// Caddy is the Schema for the caddies API
type Caddy struct {
	metav1.TypeMeta `json:",inline"`

	// metadata is a standard object metadata
	// +optional
	metav1.ObjectMeta `json:"metadata,omitzero"`

	// spec defines the desired state of Caddy
	// +required
	Spec CaddySpec `json:"spec"`

	// status defines the observed state of Caddy
	// +optional
	Status CaddyStatus `json:"status,omitzero"`
}

// +kubebuilder:object:root=true

// CaddyList contains a list of Caddy
type CaddyList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitzero"`
	Items           []Caddy `json:"items"`
}

func init() {
	SchemeBuilder.Register(func(s *runtime.Scheme) error {
		s.AddKnownTypes(SchemeGroupVersion, &Caddy{}, &CaddyList{})
		return nil
	})
}
