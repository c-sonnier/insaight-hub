package org

import (
	"fmt"
	"regexp"

	"github.com/c-sonnier/insaight-hub/cli/internal/client"
)

var uuidPattern = regexp.MustCompile(`^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`)

type Lister interface {
	ListOrganizations() ([]client.Organization, error)
}

// Resolve returns the organization UUID to use for a request, honoring
// flag → INSAIGHT_ORG → config default → sole-account → error precedence.
// INSAIGHT_ORG is expected to be baked into configOrg by config.ApplyEnv.
func Resolve(c *client.Client, flagOrg, configOrg string) (string, error) {
	return resolve(c, flagOrg, configOrg)
}

func resolve(l Lister, flagOrg, configOrg string) (string, error) {
	candidate := flagOrg
	if candidate == "" {
		candidate = configOrg
	}
	if candidate != "" && uuidPattern.MatchString(candidate) {
		return candidate, nil
	}
	orgs, err := l.ListOrganizations()
	if err != nil {
		return "", err
	}
	return Pick(candidate, orgs)
}

// Pick resolves the given candidate (name, UUID, or empty) against the
// caller's memberships.
func Pick(candidate string, orgs []client.Organization) (string, error) {
	if candidate == "" {
		if len(orgs) == 1 {
			return orgs[0].ID, nil
		}
		return "", fmt.Errorf("no organization specified; run `ih organizations list` and pass --org, or set a default via `ih login --default-org`")
	}

	for _, o := range orgs {
		if o.ID == candidate || o.Name == candidate {
			return o.ID, nil
		}
	}

	if uuidPattern.MatchString(candidate) {
		return candidate, nil
	}

	return "", fmt.Errorf("organization %q not found in your memberships", candidate)
}
