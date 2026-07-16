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

import (
	"context"
	"fmt"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/apimachinery/pkg/types"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
)

var (
	serviceMonitorGVK = schema.GroupVersionKind{
		Group: monitoringAPIGroup, Version: "v1", Kind: "ServiceMonitor",
	}
	prometheusRuleGVK = schema.GroupVersionKind{
		Group: monitoringAPIGroup, Version: "v1", Kind: "PrometheusRule",
	}
)

// ensureObservability creates/updates the per-site monitoring bundle when
// toggled on the CaddySite spec (REQ-E9-S03-01 / REQ-E9-S03-02).
func (r *CaddySiteReconciler) ensureObservability(ctx context.Context, site *gatewayv1alpha1.CaddySite) error {
	if site.Spec.Observability.ServiceMonitor {
		if err := r.ensureServiceMonitor(ctx, site); err != nil {
			return err
		}
	}
	if site.Spec.Observability.PrometheusRules {
		if err := r.ensurePrometheusRule(ctx, site); err != nil {
			return err
		}
	}
	return nil
}

func (r *CaddySiteReconciler) ensureServiceMonitor(ctx context.Context, site *gatewayv1alpha1.CaddySite) error {
	desired := &unstructured.Unstructured{}
	desired.SetGroupVersionKind(serviceMonitorGVK)
	desired.SetName(site.Name)
	desired.SetNamespace(site.Namespace)
	desired.SetLabels(adr0301Labels(site))
	desired.Object["spec"] = map[string]any{
		"selector": map[string]any{
			"matchLabels": map[string]any{
				labelKeyService:          site.Name,
				"app.kubernetes.io/name": site.Name,
			},
		},
		"endpoints": []any{
			map[string]any{
				"port":     "metrics",
				"path":     "/metrics",
				"interval": "30s",
			},
		},
	}
	if err := controllerutil.SetControllerReference(site, desired, r.Scheme); err != nil {
		return fmt.Errorf("set owner on ServiceMonitor %s/%s: %w", site.Namespace, site.Name, err)
	}
	return r.upsertUnstructured(ctx, desired, "ServiceMonitor")
}

func (r *CaddySiteReconciler) ensurePrometheusRule(ctx context.Context, site *gatewayv1alpha1.CaddySite) error {
	service := site.Name
	desired := &unstructured.Unstructured{}
	desired.SetGroupVersionKind(prometheusRuleGVK)
	desired.SetName(site.Name)
	desired.SetNamespace(site.Namespace)
	desired.SetLabels(adr0301Labels(site))
	desired.Object["spec"] = map[string]any{
		"groups": []any{
			map[string]any{
				"name": fmt.Sprintf("%s.%s.%s", labelValuePartOf, site.Namespace, site.Name),
				"rules": []any{
					map[string]any{
						"alert": "HighHTTPErrorRate",
						"expr": fmt.Sprintf(
							`sum(rate(caddy_http_request_duration_seconds_count{service="%s",code=~"5.."}[5m])) / sum(rate(caddy_http_request_duration_seconds_count{service="%s"}[5m])) > 0.05`,
							service, service,
						),
						"for": "5m",
						"labels": map[string]any{
							"severity":      "warning",
							labelKeyService: service,
							labelKeyOwner:   labelOrDefault(site, labelKeyOwner, labelValueOwnerDef),
						},
						"annotations": map[string]any{
							"summary":     fmt.Sprintf("%s HTTP 5xx error rate above 5%%", service),
							"description": fmt.Sprintf("%s is returning 5xx for more than 5%% of requests over 5m.", service),
						},
					},
				},
			},
		},
	}
	if err := controllerutil.SetControllerReference(site, desired, r.Scheme); err != nil {
		return fmt.Errorf("set owner on PrometheusRule %s/%s: %w", site.Namespace, site.Name, err)
	}
	return r.upsertUnstructured(ctx, desired, "PrometheusRule")
}

func (r *CaddySiteReconciler) upsertUnstructured(ctx context.Context, desired *unstructured.Unstructured, kind string) error {
	key := types.NamespacedName{Namespace: desired.GetNamespace(), Name: desired.GetName()}
	existing := &unstructured.Unstructured{}
	existing.SetGroupVersionKind(desired.GroupVersionKind())
	err := r.Get(ctx, key, existing)
	switch {
	case apierrors.IsNotFound(err):
		if cerr := r.Create(ctx, desired); cerr != nil {
			return fmt.Errorf("create %s %s: %w", kind, key, cerr)
		}
		return nil
	case err != nil:
		return fmt.Errorf("get %s %s: %w", kind, key, err)
	}

	desired.SetResourceVersion(existing.GetResourceVersion())
	desired.SetUID(existing.GetUID())
	if err := r.Update(ctx, desired); err != nil {
		if apierrors.IsConflict(err) {
			return nil // next reconcile will converge
		}
		return fmt.Errorf("update %s %s: %w", kind, key, err)
	}
	return nil
}

// adr0301Labels is the mandatory core set (ADR-0301) plus k8s mirrors.
func adr0301Labels(site *gatewayv1alpha1.CaddySite) map[string]string {
	owner := labelOrDefault(site, labelKeyOwner, labelValueOwnerDef)
	track := labelOrDefault(site, labelKeyTrack, labelValueTrackDef)
	class := labelOrDefault(site, labelKeyDataClassification, labelValueClassDef)
	crit := labelOrDefault(site, labelKeyBusinessCriticality, labelValueCritDef)
	return map[string]string{
		labelKeyOwner:                  owner,
		labelKeyService:                site.Name,
		labelKeyPartOf:                 labelValuePartOf,
		labelKeyManagedBy:              labelValueManagedBy,
		labelKeyDataClassification:     class,
		labelKeyBusinessCriticality:    crit,
		labelKeyTrack:                  track,
		"app.kubernetes.io/name":       site.Name,
		"app.kubernetes.io/part-of":    labelValuePartOf,
		"app.kubernetes.io/managed-by": labelValueManagedBy,
	}
}

func labelOrDefault(site *gatewayv1alpha1.CaddySite, key, fallback string) string {
	if site.Labels != nil {
		if v := site.Labels[key]; v != "" {
			return v
		}
	}
	return fallback
}
