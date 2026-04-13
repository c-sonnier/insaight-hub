package org

import (
	"testing"

	"github.com/c-sonnier/insaight-hub/cli/internal/client"
)

func TestPick_SoleAccountFallbackWhenCandidateEmpty(t *testing.T) {
	orgs := []client.Organization{{ID: "uuid-a", Name: "Acme"}}

	got, err := Pick("", orgs)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "uuid-a" {
		t.Errorf("got %q, want uuid-a", got)
	}
}

func TestPick_ErrorWhenNoCandidateAndMultipleOrgs(t *testing.T) {
	orgs := []client.Organization{
		{ID: "uuid-a", Name: "Acme"},
		{ID: "uuid-b", Name: "Beta"},
	}

	_, err := Pick("", orgs)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestPick_ErrorWhenNoCandidateAndZeroOrgs(t *testing.T) {
	_, err := Pick("", nil)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestPick_MatchesByName(t *testing.T) {
	orgs := []client.Organization{
		{ID: "uuid-a", Name: "Acme"},
		{ID: "uuid-b", Name: "Beta"},
	}

	got, err := Pick("Beta", orgs)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "uuid-b" {
		t.Errorf("got %q, want uuid-b", got)
	}
}

func TestPick_MatchesByUUID(t *testing.T) {
	orgs := []client.Organization{
		{ID: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", Name: "Acme"},
	}

	got, err := Pick("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", orgs)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" {
		t.Errorf("got %q, want uuid", got)
	}
}

func TestPick_UnknownNameReturnsError(t *testing.T) {
	orgs := []client.Organization{{ID: "uuid-a", Name: "Acme"}}

	_, err := Pick("Gamma", orgs)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestPick_UnknownUUIDPassesThrough(t *testing.T) {
	// Identity may have just been granted access; pass the UUID to the server.
	orgs := []client.Organization{{ID: "uuid-a", Name: "Acme"}}

	got, err := Pick("11111111-2222-3333-4444-555555555555", orgs)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "11111111-2222-3333-4444-555555555555" {
		t.Errorf("got %q, want pass-through UUID", got)
	}
}

type fakeLister struct {
	orgs []client.Organization
	err  error
	hits int
}

func (f *fakeLister) ListOrganizations() ([]client.Organization, error) {
	f.hits++
	return f.orgs, f.err
}

func TestResolve_UUIDShortCircuitsAPI(t *testing.T) {
	lister := &fakeLister{orgs: []client.Organization{{ID: "uuid-a", Name: "Acme"}}}

	got, err := resolve(lister, "11111111-2222-3333-4444-555555555555", "file-org")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "11111111-2222-3333-4444-555555555555" {
		t.Errorf("got %q, want UUID", got)
	}
	if lister.hits != 0 {
		t.Errorf("expected 0 API calls, got %d", lister.hits)
	}
}

func TestResolve_FlagBeatsConfig(t *testing.T) {
	lister := &fakeLister{orgs: []client.Organization{
		{ID: "uuid-a", Name: "Acme"},
		{ID: "uuid-b", Name: "Beta"},
	}}

	got, err := resolve(lister, "Beta", "Acme")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "uuid-b" {
		t.Errorf("got %q, want uuid-b", got)
	}
}

func TestResolve_FallsBackToConfig(t *testing.T) {
	lister := &fakeLister{orgs: []client.Organization{
		{ID: "uuid-a", Name: "Acme"},
		{ID: "uuid-b", Name: "Beta"},
	}}

	got, err := resolve(lister, "", "Acme")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "uuid-a" {
		t.Errorf("got %q, want uuid-a", got)
	}
}

func TestResolve_SoleAccountFallback(t *testing.T) {
	lister := &fakeLister{orgs: []client.Organization{{ID: "uuid-a", Name: "Acme"}}}

	got, err := resolve(lister, "", "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "uuid-a" {
		t.Errorf("got %q, want uuid-a", got)
	}
}
