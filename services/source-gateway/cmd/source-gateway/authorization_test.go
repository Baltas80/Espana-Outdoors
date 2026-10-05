package main

import "testing"

func TestAuthorizeClientRoleAcceptsRoleFromConfiguredClient(t *testing.T) {
    claims := map[string]any{
        "realm_access": map[string]any{"roles": []any{"source.read"}},
        "resource_access": map[string]any{
            "espana-outdoor": map[string]any{"roles": []any{"source.read"}},
            "another-client": map[string]any{"roles": []any{"admin"}},
        },
    }
    if err := authorizeClientRole(claims, "espana-outdoor", "source.read"); err != nil {
        t.Fatalf("expected configured client role to be accepted: %v", err)
    }
}

func TestAuthorizeClientRoleRejectsRealmRoleOnly(t *testing.T) {
    claims := map[string]any{
        "realm_access": map[string]any{"roles": []any{"source.read"}},
        "resource_access": map[string]any{},
    }
    if err := authorizeClientRole(claims, "espana-outdoor", "source.read"); err == nil {
        t.Fatal("expected realm role to be rejected as client authorization")
    }
}

func TestAuthorizeClientRoleRejectsRoleFromAnotherClient(t *testing.T) {
    claims := map[string]any{
        "resource_access": map[string]any{
            "another-client": map[string]any{"roles": []any{"source.read"}},
        },
    }
    if err := authorizeClientRole(claims, "espana-outdoor", "source.read"); err == nil {
        t.Fatal("expected role from another client to be rejected")
    }
}

func TestAuthorizeClientRoleRejectsSameRoleNameUnderWrongClient(t *testing.T) {
    claims := map[string]any{
        "resource_access": map[string]any{
            "another-client": map[string]any{"roles": []any{"source.read"}},
            "espana-outdoor": map[string]any{"roles": []any{"source.other"}},
        },
    }
    if err := authorizeClientRole(claims, "espana-outdoor", "source.read"); err == nil {
        t.Fatal("expected same role name in another client to be rejected")
    }
}

func TestAuthorizeClientRoleRejectsMalformedAndMissingClaims(t *testing.T) {
    cases := []map[string]any{
        {},
        {"resource_access": "malformed"},
        {"resource_access": map[string]any{"espana-outdoor": map[string]any{"roles": "malformed"}}},
        {"resource_access": map[string]any{"espana-outdoor": map[string]any{"roles": []any{"admin"}}}},
    }
    for i, claims := range cases {
        if err := authorizeClientRole(claims, "espana-outdoor", "source.read"); err == nil {
            t.Fatalf("case %d: expected authorization rejection", i)
        }
    }
}

func TestAuthorizeClientRoleRejectsPrivilegeEscalationAcrossClients(t *testing.T) {
    claims := map[string]any{
        "resource_access": map[string]any{
            "espana-outdoor": map[string]any{"roles": []any{"source.read"}},
            "admin-client": map[string]any{"roles": []any{"admin"}},
        },
    }
    if err := authorizeClientRole(claims, "espana-outdoor", "admin"); err == nil {
        t.Fatal("expected admin privilege from another client to be rejected")
    }
}
