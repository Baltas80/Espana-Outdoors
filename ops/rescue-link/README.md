# Rescue Link production gate

This deployment package runs the first-party Rescue Link backend with PostgreSQL. Authentication remains external through Keycloak/OIDC.

## Production requirements

- Terminate public traffic at an HTTPS reverse proxy.
- Keep the application container bound to loopback; do not expose port 8080 directly.
- Inject `DATABASE_URL`, `OIDC_ISSUER`, `OIDC_AUDIENCE`, `PUBLIC_SHARE_BASE_URL` and `LOCATION_ENCRYPTION_KEY` through the deployment secret/configuration system.
- Use a 32-byte location encryption key and rotate it under a documented key-management procedure. Existing ciphertext cannot be decrypted after an incompatible key rotation.
- Configure Keycloak roles exactly as documented by the service.
- Use managed PostgreSQL/PostGIS or a hardened PostgreSQL host for production; the compose database is a reproducible reference/staging baseline.
- Pin container image digests in the final production deployment rather than mutable tags.
- Back up PostgreSQL and verify restore procedures before release.
- Monitor `/healthz`, HTTP error rates, latency, database saturation and cleanup failures.
- Never log access tokens, share tokens, capability tokens or exact emergency coordinates.

## Staging validation

```bash
cp ops/rescue-link/.env.example ops/rescue-link/.env
# Fill values through a secret manager or a local-only staging environment.

docker compose -f ops/rescue-link/docker-compose.yml config
docker compose -f ops/rescue-link/docker-compose.yml up -d --build
curl --fail http://127.0.0.1:8080/healthz
```

The service performs OIDC discovery, database connectivity checks and migrations during startup. A healthy response means the process and database path are reachable; it does not replace end-to-end authentication/authorization tests.

## Release gate

Run the Rescue Link API integration tests with a real Keycloak realm and PostgreSQL instance before public release. Validate create, expiry, revoke, role separation, capability expiry, responder limits and the rule that public previews never disclose exact location.
