package cobra

import (
	"github.com/khulnasoft-lab/tracker/pkg/cmd/flags"
	k8s "github.com/khulnasoft-lab/tracker/pkg/k8s/apis/tracker.khulnasoft.com/v1beta1"
	"github.com/khulnasoft-lab/tracker/pkg/policy"
	"github.com/khulnasoft-lab/tracker/pkg/policy/v1beta1"
)

func createPoliciesFromK8SPolicy(policies []k8s.PolicyInterface) (*policy.Policies, error) {
	policyScopeMap, policyEventsMap, err := flags.PrepareFilterMapsFromPolicies(policies)
	if err != nil {
		return nil, err
	}

	return flags.CreatePolicies(policyScopeMap, policyEventsMap, true)
}

func createPoliciesFromPolicyFiles(policyFlags []string) (*policy.Policies, error) {
	policyFiles, err := v1beta1.PoliciesFromPaths(policyFlags)
	if err != nil {
		return nil, err
	}

	policyScopeMap, policyEventsMap, err := flags.PrepareFilterMapsFromPolicies(policyFiles)
	if err != nil {
		return nil, err
	}

	return flags.CreatePolicies(policyScopeMap, policyEventsMap, true)
}

func createPoliciesFromCLIFlags(scopeFlags, eventFlags []string) (*policy.Policies, error) {
	policyScopeMap, err := flags.PrepareScopeMapFromFlags(scopeFlags)
	if err != nil {
		return nil, err
	}

	policyEventsMap, err := flags.PrepareEventMapFromFlags(eventFlags)
	if err != nil {
		return nil, err
	}

	return flags.CreatePolicies(policyScopeMap, policyEventsMap, true)
}
