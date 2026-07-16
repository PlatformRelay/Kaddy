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
	"errors"
	"fmt"
	"time"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	logf "sigs.k8s.io/controller-runtime/pkg/log"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin"
)

// routeCleanupFinalizer guards deletion until the route is removed from
// the dataplane (graceful drain, ADR-0401).
const routeCleanupFinalizer = "gateway.kaddy.io/route-cleanup"

// defaultRoutesPath is where new routes are appended in the Caddy config.
const defaultRoutesPath = "/config/apps/http/servers/srv0/routes"

// missingRefRequeue retries resolution of a dangling caddyRef without
// hot-looping the workqueue (terminal-ish config error).
const missingRefRequeue = 30 * time.Second

// CaddySiteReconciler reconciles a CaddySite object
type CaddySiteReconciler struct {
	client.Client
	Scheme *runtime.Scheme

	// AdminURL resolves the admin API base URL for the referenced Caddy
	// dataplane. Defaults to the in-cluster Service DNS name; tests inject a fake.
	AdminURL func(*gatewayv1alpha1.Caddy) string

	// RoutesPath is the config path routes are appended to on create.
	// Defaults to defaultRoutesPath.
	RoutesPath string
}

// +kubebuilder:rbac:groups=gateway.kaddy.io,resources=caddysites,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=gateway.kaddy.io,resources=caddysites/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=gateway.kaddy.io,resources=caddysites/finalizers,verbs=update
// +kubebuilder:rbac:groups=gateway.kaddy.io,resources=caddies,verbs=get;list;watch

// Reconcile renders the site's route (tagged with a stable `@id`) and
// upserts it idempotently through the Caddy admin API (REQ-E9-S02-02):
// PUT /id/<id> replaces in place; only a missing route is POSTed once.
func (r *CaddySiteReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := logf.FromContext(ctx)

	site := &gatewayv1alpha1.CaddySite{}
	if err := r.Get(ctx, req.NamespacedName, site); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	caddy := &gatewayv1alpha1.Caddy{}
	refKey := types.NamespacedName{Namespace: site.Namespace, Name: site.Spec.CaddyRef}
	if err := r.Get(ctx, refKey, caddy); err != nil {
		if !apierrors.IsNotFound(err) {
			return ctrl.Result{}, fmt.Errorf("resolve caddyRef %s: %w", refKey, err)
		}
		if !site.DeletionTimestamp.IsZero() {
			// Dataplane is gone — nothing left to drain.
			return ctrl.Result{}, r.removeFinalizer(ctx, site)
		}
		log.Info("caddyRef not found", "caddysite", req.NamespacedName, "caddyRef", refKey)
		if err := r.setReady(ctx, site, metav1.ConditionFalse, "CaddyRefNotFound",
			fmt.Sprintf("referenced Caddy %q not found in namespace %s", site.Spec.CaddyRef, site.Namespace)); err != nil {
			return ctrl.Result{}, err
		}
		return ctrl.Result{RequeueAfter: missingRefRequeue}, nil
	}

	admin := caddyadmin.New(r.adminURL(caddy))

	if !site.DeletionTimestamp.IsZero() {
		if !controllerutil.ContainsFinalizer(site, routeCleanupFinalizer) {
			return ctrl.Result{}, nil
		}
		if err := admin.DeleteRoute(ctx, routeID(site)); err != nil {
			if errors.Is(err, caddyadmin.ErrUnavailable) {
				log.Info("admin API unavailable during drain, retrying", "caddysite", req.NamespacedName)
				return ctrl.Result{RequeueAfter: transientRequeue}, nil
			}
			return ctrl.Result{}, fmt.Errorf("drain route for CaddySite %s: %w", req.NamespacedName, err)
		}
		return ctrl.Result{}, r.removeFinalizer(ctx, site)
	}

	if !controllerutil.ContainsFinalizer(site, routeCleanupFinalizer) {
		controllerutil.AddFinalizer(site, routeCleanupFinalizer)
		if err := r.Update(ctx, site); err != nil {
			if apierrors.IsConflict(err) {
				return ctrl.Result{RequeueAfter: time.Second}, nil
			}
			return ctrl.Result{}, fmt.Errorf("add finalizer to CaddySite %s: %w", req.NamespacedName, err)
		}
	}

	if err := admin.UpsertRoute(ctx, r.routesPath(), renderRoute(site)); err != nil {
		if errors.Is(err, caddyadmin.ErrUnavailable) {
			log.Info("caddy admin API unavailable", "caddysite", req.NamespacedName, "error", err.Error())
			if serr := r.setReady(ctx, site, metav1.ConditionFalse, "AdminAPIUnavailable",
				"Caddy admin API is unavailable"); serr != nil {
				return ctrl.Result{}, serr
			}
			return ctrl.Result{RequeueAfter: transientRequeue}, nil
		}
		return ctrl.Result{}, fmt.Errorf("upsert route for CaddySite %s: %w", req.NamespacedName, err)
	}

	if err := r.setReady(ctx, site, metav1.ConditionTrue, "Configured",
		"route configured on the Caddy dataplane"); err != nil {
		return ctrl.Result{}, err
	}
	return ctrl.Result{}, nil
}

// setReady mirrors the reconcile outcome into status (Ready condition +
// observedGeneration) with optimistic-concurrency tolerance.
func (r *CaddySiteReconciler) setReady(ctx context.Context, site *gatewayv1alpha1.CaddySite,
	status metav1.ConditionStatus, reason, message string) error {
	meta.SetStatusCondition(&site.Status.Conditions, metav1.Condition{
		Type:               conditionReady,
		Status:             status,
		Reason:             reason,
		Message:            message,
		ObservedGeneration: site.Generation,
	})
	site.Status.ObservedGeneration = site.Generation
	if err := r.Status().Update(ctx, site); err != nil && !apierrors.IsConflict(err) {
		return fmt.Errorf("update CaddySite %s/%s status: %w", site.Namespace, site.Name, err)
	}
	return nil
}

func (r *CaddySiteReconciler) removeFinalizer(ctx context.Context, site *gatewayv1alpha1.CaddySite) error {
	if !controllerutil.ContainsFinalizer(site, routeCleanupFinalizer) {
		return nil
	}
	controllerutil.RemoveFinalizer(site, routeCleanupFinalizer)
	if err := r.Update(ctx, site); err != nil && !apierrors.IsNotFound(err) {
		return fmt.Errorf("remove finalizer from CaddySite %s/%s: %w", site.Namespace, site.Name, err)
	}
	return nil
}

func (r *CaddySiteReconciler) adminURL(caddy *gatewayv1alpha1.Caddy) string {
	if r.AdminURL != nil {
		return r.AdminURL(caddy)
	}
	return DefaultAdminURL(caddy)
}

func (r *CaddySiteReconciler) routesPath() string {
	if r.RoutesPath != "" {
		return r.RoutesPath
	}
	return defaultRoutesPath
}

// routeID is the stable `@id` a CaddySite's route is upserted under.
func routeID(site *gatewayv1alpha1.CaddySite) string {
	return fmt.Sprintf("kaddy.%s.%s", site.Namespace, site.Name)
}

// renderRoute renders the CaddySite into one Caddy route object: a host
// matcher wrapping a subroute per declared path -> backend Service.
func renderRoute(site *gatewayv1alpha1.CaddySite) caddyadmin.Route {
	hosts := make([]any, 0, len(site.Spec.Hosts))
	for _, h := range site.Spec.Hosts {
		hosts = append(hosts, h)
	}

	subroutes := make([]any, 0, len(site.Spec.Routes))
	for _, rt := range site.Spec.Routes {
		path := rt.Path
		if path == "" {
			path = "/"
		}
		subroutes = append(subroutes, map[string]any{
			"match": []any{map[string]any{"path": []any{path + "*"}}},
			"handle": []any{map[string]any{
				"handler": "reverse_proxy",
				"upstreams": []any{map[string]any{
					"dial": fmt.Sprintf("%s.%s.svc.cluster.local:%d",
						rt.Backend.ServiceName, site.Namespace, rt.Backend.Port),
				}},
			}},
		})
	}

	return caddyadmin.Route{
		ID: routeID(site),
		Body: map[string]any{
			"match": []any{map[string]any{"host": hosts}},
			"handle": []any{map[string]any{
				"handler": "subroute",
				"routes":  subroutes,
			}},
			"terminal": true,
		},
	}
}

// SetupWithManager sets up the controller with the Manager.
func (r *CaddySiteReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&gatewayv1alpha1.CaddySite{}).
		Named("caddysite").
		Complete(r)
}
