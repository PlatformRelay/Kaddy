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
	"time"

	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	logf "sigs.k8s.io/controller-runtime/pkg/log"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
	"github.com/PlatformRelay/Kaddy/operator/internal/caddyadmin"
)

// conditionReady is the top-level readiness condition on Caddy and CaddySite.
const conditionReady = "Ready"

// transientRequeue is the backoff for AdminAPIUnavailable — level-based
// retry without erroring (and hot-looping) the workqueue.
const transientRequeue = 15 * time.Second

// CaddyReconciler reconciles a Caddy object
type CaddyReconciler struct {
	client.Client
	Scheme *runtime.Scheme

	// AdminURL resolves the admin API base URL for a Caddy dataplane.
	// Defaults to the in-cluster Service DNS name; tests inject a fake.
	AdminURL func(*gatewayv1alpha1.Caddy) string
}

// +kubebuilder:rbac:groups=gateway.kaddy.io,resources=caddies,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=gateway.kaddy.io,resources=caddies/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=gateway.kaddy.io,resources=caddies/finalizers,verbs=update

// Reconcile checks that the dataplane's admin API is reachable and mirrors
// the outcome into the Ready condition (REQ-E9-S02-01). Deploying the
// dataplane itself (Deployment/Service) is E9-S03 scope.
func (r *CaddyReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := logf.FromContext(ctx)

	caddy := &gatewayv1alpha1.Caddy{}
	if err := r.Get(ctx, req.NamespacedName, caddy); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	admin := caddyadmin.New(r.adminURL(caddy))

	result := ctrl.Result{}
	cond := metav1.Condition{
		Type:               conditionReady,
		Status:             metav1.ConditionTrue,
		Reason:             "AdminAPIReachable",
		Message:            "Caddy admin API is reachable",
		ObservedGeneration: caddy.Generation,
	}
	if err := admin.Ping(ctx); err != nil {
		// Transient by taxonomy: degrade status and requeue with backoff
		// instead of erroring the workqueue.
		log.Info("caddy admin API unavailable", "caddy", req.NamespacedName, "error", err.Error())
		cond.Status = metav1.ConditionFalse
		cond.Reason = "AdminAPIUnavailable"
		cond.Message = "Caddy admin API is unavailable"
		result.RequeueAfter = transientRequeue
	}

	meta.SetStatusCondition(&caddy.Status.Conditions, cond)
	caddy.Status.ObservedGeneration = caddy.Generation
	if err := r.Status().Update(ctx, caddy); err != nil {
		if apierrors.IsConflict(err) {
			return ctrl.Result{RequeueAfter: time.Second}, nil // optimistic concurrency: retry
		}
		return ctrl.Result{}, fmt.Errorf("update Caddy %s status: %w", req.NamespacedName, err)
	}
	return result, nil
}

func (r *CaddyReconciler) adminURL(caddy *gatewayv1alpha1.Caddy) string {
	if r.AdminURL != nil {
		return r.AdminURL(caddy)
	}
	return DefaultAdminURL(caddy)
}

// SetupWithManager sets up the controller with the Manager.
func (r *CaddyReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&gatewayv1alpha1.Caddy{}).
		Named("caddy").
		Complete(r)
}
