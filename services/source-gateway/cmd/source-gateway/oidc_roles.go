package main

import (
    "errors"
    "fmt"
)

// authorizeClientRole accepts only a role explicitly assigned to the configured
// OIDC client in resource_access. Realm-wide roles and roles belonging to any
// other client are deliberately not considered authorization for this service.
func authorizeClientRole(claims map[string]any, clientID, requiredRole string) error {
    clientID = stringsTrim(clientID)
    requiredRole = stringsTrim(requiredRole)
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
        if ok && stringsTrim(role) == requiredRole {
            return nil
        }
    }
    return fmt.Errorf("required client role %q missing", requiredRole)
}

func stringsTrim(value string) string {
    for len(value) > 0 && (value[0] == ' ' || value[0] == '\t' || value[0] == '\n' || value[0] == '\r') {
        value = value[1:]
    }
    for len(value) > 0 && (value[len(value)-1] == ' ' || value[len(value)-1] == '\t' || value[len(value)-1] == '\n' || value[len(value)-1] == '\r') {
        value = value[:len(value)-1]
    }
    return value
}
