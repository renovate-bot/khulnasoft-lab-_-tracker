package controller

import (
	"context"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	"github.com/khulnasoft-lab/tracker/pkg/k8s/apis/tracker.khulnasoft.com/v1beta1"
)

// PolicyReconciler is the main controller for the Tracker Policy CRD. It is responsible
// for updating the Tracker DaemonSet whenever a change is detected in a TrackerPolicy
// object.
type PolicyReconciler struct {
	client.Client
	Scheme           *runtime.Scheme
	TrackerNamespace string
	TrackerName      string
}

// +kubebuilder:rbac:groups=tracker.khulnasoft.com,resources=policies,verbs=get;list;watch;
// +kubebuilder:rbac:groups=apps,resources=daemonsets,verbs=get;list;watch;patch;update;

// Reconcile is where the reconciliation logic resides. Every time a change is detected in
// a v1beta1.Policy object, this function will be called. It will update the Tracker
// DaemonSet, so that the Tracker pods will be restarted with the new policy. It does this
// by adding a timestamp annotation to the pod template, so that the daemonset controller
// will rollout a new daemonset ("restarting" the daemonset).
func (r *PolicyReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	var ds appsv1.DaemonSet

	key := client.ObjectKey{
		Namespace: r.TrackerNamespace,
		Name:      r.TrackerName,
	}
	if err := r.Get(ctx, key, &ds); err != nil {
		logger.Error(err, "unable to fetch daemonset")
		return ctrl.Result{}, err
	}

	if ds.Spec.Template.Annotations == nil {
		ds.Spec.Template.Annotations = make(map[string]string)
	}

	// we use the same strategy done by kubect rollout restart,
	// adding a timestamp annotation to the pod template,
	// so that the daemonset controller will rollout a new daemonset
	ds.Spec.Template.Annotations["tracker-operator-restarted"] = time.Now().String()

	if err := r.Update(ctx, &ds); err != nil {
		logger.Error(err, "unable to update daemonset")
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}

// SetupWithManager is responsible for connecting the PolicyReconciler to the main
// controller manager. It tells the manager that for changes in v1beta1Policy objects, the
// PolicyReconciler should be invoked.
func (r *PolicyReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&v1beta1.Policy{}).
		Complete(r)
}
