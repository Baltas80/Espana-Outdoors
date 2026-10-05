package main

import "testing"

func TestAuthorizeClientRoleAcceptsRoleForConfiguredClient(t *testing.T) {
    claims := map[string]any{
        "resource_access": map[string]any{
            "espana-outdoors-mobile": map[string]any{
                "roles": []any{"source.read"},
            },
        },
    }

    if err := authorizeClientRole(claims, "espana-outdoors-mobile", "source.read"); err != nil {
        t.Fatalf("expected configured client role to be accepted: %v", err)
    }
}

func TestAuthorizeClientRoleRejectsRoleFromAnotherClient(t *testing.T) {
    claims := map[string]any{
        "resource_access": map[string]any{
            "another-client": map[string]any{
                "roles": []any{"source.read"},
            },
        },
    }

    if err := authorizeClientRole(claims, "espana-outdoors-mobile", "source.read"); err == nil {
        t.Fatal("expected role belonging to another client to be rejected")
    }
}

func TestAuthorizeClientRoleRejectsRealmRole(t *testing.T) {
    claims := map[string]any{
        "realm_access": map[string]any{
            "roles": []any{"source.read"},
        },
        "resource_access": map[string]any{},
    }

    if err := authorizeClientRole(claims, "espana-outdoors-mobile", "source.read"); err == nil {
        t.Fatal("expected realm role to be rejected when client role is absent")
    }
}

func TestAuthorizeClientRoleRejectsSameRoleNameOnWrongClient(t *testing.T) {
    claims := map[string]any{
        "resource_access": map[string]any{
            "another-client": map[string]any{
                "roles": []any{"source.read"},
            },
            "espana-outdoors-mobile": map[string]any{
                "roles": []any{"profile.read"},
            },
        },
    }

    if err := authorizeClientRole(claims, "espana-outdoors-mobile", "source.read"); err == nil {
        t.Fatal("expected same role name on another client to be rejected")
    }
}

func TestAuthorizeClientRoleRejectsMissingClaims(t *testing.T) {
    cases := []map[string]any{
        {},
        {"resource_access": "invalid"},
        {"resource_access": map[string]any{"espana-outdoors-mobile": map[string]any{}}},
        {"resource_access": map[string]any{"espana-outdoors-mobile": map[string]any{"roles": "source.read"}}},
    }

    for i, claims := range cases {
        if err := authorizeClientRole(claims, "espana-outdoors-mobile", "source.read"); err == nil {
            t.Fatalf("case %d: expected malformed or missing role claims to be rejected", i)
        }
    }
}

func TestAuthorizeClientRoleRejectsWrongRequiredRole(t *testing.T) {
    claims := map[string]any{
        "resource_access": map[string]any{
            "espana-outdoors-mobile": map[string]any{
                "roles": []any{"profile.read"},
            },
        },
    }

    if err := authorizeClientRole(claims, "espana-outdoors-mobile", "source.read"); err == nil {
        t.Fatal("expected insufficient client role to be rejected")
    }
}
