package main

import (
    "errors"
    "fmt"
    "strings"
)

// authorizeClientRole implements the gateway authorization boundary for OIDC roles.
// Only roles under resource_access[clientID].roles are considered client roles.
// realm_access.roles is intentionally never promoted to a client authorization.
func authorizeClientRole(claims map[string]any, clientID, requiredRole string) error {
    clientID = strings.TrimSpace(clientID)
    requiredRole = strings.TrimSpace(requiredRole)
    if clientID == "" || requiredRole == "" {
        return errors.New("OIDC client authorization policy is not configured")
    }

    resourceAccess, ok := claims["resource_access"].(map[string]any)
    if !ok {
        return errors.New("resource_access claim missing or malformed")
    }

    clientClaims, ok := resourceAccess[clientID].(map[string]any)
    if !ok {
        return fmt.Errorf("authorization for OIDC client %q is missing", clientID)
    }

    roles, ok := clientClaims["roles"].([]any)
    if !ok {
        return errors.New("client roles claim missing or malformed")
    }

    for _, rawRole := range roles {
        role, ok := rawRole.(string)
        if ok && role == requiredRole {
            return nil
        }
    }

    return fmt.Errorf("required role %q is not granted to OIDC client %q", requiredRole, clientID)
}
