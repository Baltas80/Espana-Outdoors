# Rescue Link service

Backend first-party para Rescue Link. La app móvil no confía en expiración local para seguridad.

## Requisitos

- Go 1.27.1
- PostgreSQL/PostGIS accesible
- Keycloak/OIDC con `sub` y roles de Rescue Link
- Una clave AES-256 para `LOCATION_ENCRYPTION_KEY`

## Roles OIDC

- `rescue:official`
- `rescue:verified-professional`
- `rescue:trusted-contact`
- `rescue:volunteer`

## Variables

| Variable | Obligatoria | Descripción |
|---|---|---|
| DATABASE_URL | Sí | PostgreSQL |
| OIDC_ISSUER | Sí | Issuer OIDC accesible por el servicio |
| OIDC_AUDIENCE | Sí | Audience del access token |
| PUBLIC_SHARE_BASE_URL | Sí | URL pública HTTPS del enlace |
| LOCATION_ENCRYPTION_KEY | Sí | Base64/hex de exactamente 32 bytes |
| RESCUE_MAX_TTL | No | TTL máximo de un enlace, por defecto 15m |
| RESCUE_RETENTION | No | Retención de registros, por defecto 24h |
| RESCUE_CAPABILITY_TTL | No | TTL de capacidad, por defecto 5m |
| RESCUE_MAX_RESPONDERS | No | Máximo de respondedores por enlace, por defecto 5 |
| RESCUE_RATE_LIMIT_RPS | No | Rate limit, por defecto 2 req/s |
| RESCUE_RATE_LIMIT_BURST | No | Burst, por defecto 10 |
| ENABLE_HSTS | No | Activa HSTS cuando el servicio está detrás de HTTPS |
| ALLOW_HTTP_DEV | No | Solo desarrollo local |
| RESCUE_MIGRATION_PATH | No | Ruta del SQL, por defecto `migrations/001_rescue_links.sql` |

## Seguridad

- Las coordenadas exactas se almacenan cifradas con AES-256-GCM.
- Los tokens compartidos y las capacidades solo se almacenan como SHA-256.
- La vista pública nunca devuelve coordenadas.
- La revocación se aplica al servidor.
- Los voluntarios reciben ubicación aproximada; los roles autorizados reciben la precisión definida por la política.
- Los logs de aplicación no incluyen coordenadas ni tokens.
- Producción debe usar HTTPS; `ALLOW_HTTP_DEV` no debe habilitarse.