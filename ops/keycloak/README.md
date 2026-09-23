# Keycloak development stack

This stack is for local integration testing only. Production must run Keycloak behind TLS/reverse proxy, with a managed PostgreSQL database, backups, monitoring and a controlled realm configuration.

## Start

Set secrets in the shell or an untracked `.env` file:

```bash
export KEYCLOAK_DB_PASSWORD='change-me'
export KEYCLOAK_ADMIN_PASSWORD='change-me-too'
docker compose up -d
```

Keycloak is available on `http://127.0.0.1:8080`.

Create an OIDC realm/client in the admin console using the redirect URI appropriate for the target platform. Do not commit exported realm files containing users, secrets or environment-specific callback URLs.

The Flutter client consumes the standard discovery endpoint through `OIDC_ISSUER` and uses Authorization Code + PKCE.
