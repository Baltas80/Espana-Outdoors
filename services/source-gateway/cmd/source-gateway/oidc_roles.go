package main

import (
    "errors"
    "fmt"
    "strings"
)

// authorizeClientRole accepts only a role explicitly assigned to the configured
// OIDC client in resource_access. Realm-wide roles and roles belonging to any
// other client are deliberately not considered authorization for this service.
func authorizeClientRole(claims map[string]any, clientID, requiredRole string) error {
    clientID = strings.TrimSpace(clientID)
    requiredRole = strings.TrimSpace(requiredRole)
    if clientID == "" || requiredRole == "" {
        return errors.New("OIDC client and required role are required")
    }

    resourceAccess, ok := claims["resource_access"].(map[string]any)
    if !ok {
        return errors.New("resource_access claim missing")
    }

    clientEntry, ok := resourceAccess[clientID].(map[string]any)
    if !ok {
        return fmt.Errorf("roles for OIDC client %q missing", clientID)
    }

    roles, ok := clientEntry["roles"].([]any)
    if !ok {
        return errors.New("client roles claim missing")
    }

    for _, rawRole := range roles {
        role, ok := rawRole.(string)
        if ok && strings.TrimSpace(role) == requiredRole {
            return nil
        }
    }
    return fmt.Errorf("required client role %q missing", requiredRole)
}
