# Rescue Link API

Rescue Link es un canal de coordinación de emergencia. No sustituye al 112 ni a los servicios profesionales.

## Principios de seguridad

El cliente puede capturar la posición exacta localmente, pero la autorización, la caducidad y la revocación son responsabilidad del backend de primera parte.

La vista pública solo confirma que el enlace está activo. Nunca devuelve coordenadas.

La ubicación exacta o temporal solo se devuelve después de una aceptación autenticada y conforme al rol.

El token compartido y la capacidad de sesión son valores opacos. El servidor almacena únicamente hashes de esos valores.

## POST /v1/rescue-links

Crea una sesión autenticada.

Request:

{
  "latitude": 40.4,
  "longitude": -3.7,
  "accuracyMeters": 8.0,
  "type": "lost",
  "expiresAt": "2026-09-23T15:30:00Z"
}

Response:

{
  "id": "rl_01J...",
  "shareToken": "opaque-server-token",
  "shareUrl": "https://rescue.example.com/r/opaque-server-token",
  "expiresAt": "2026-09-23T15:30:00Z"
}

## POST /v1/rescue-links/{id}/accept

Requiere autenticación y una capacidad de enlace válida. El rol se obtiene del access token OIDC; no lo elige el cliente.

Request:

{
  "shareToken": "opaque-server-token"
}

Response:

{
  "id": "rl_01J...",
  "capabilityToken": "temporary-capability",
  "expiresAt": "2026-09-23T15:35:00Z",
  "role": "trustedContact",
  "location": {
    "latitude": 40.4,
    "longitude": -3.7,
    "accuracyMeters": 8,
    "capturedAt": "2026-09-23T15:20:00Z",
    "type": "lost",
    "exact": true
  }
}

Los voluntarios reciben ubicación aproximada. Los roles autorizados reciben la precisión definida por política.

## POST /v1/rescue-links/{id}/revoke

Solo el propietario autenticado puede revocar el enlace. La revocación es inmediata y también invalida las capacidades emitidas.

## GET /v1/rescue-links/{id}/location

Requiere autenticación del responder y el header `X-Rescue-Capability` emitido durante la aceptación. El servidor vuelve a comprobar expiración y revocación antes de revelar ubicación.

## GET /r/{token}

Endpoint público para abrir un enlace compartido. Solo devuelve estado activo/caducado y una instrucción para autenticarse; no expone coordenadas.

## Controles obligatorios

- Keycloak/OIDC.
- HTTPS en producción y HSTS en el edge.
- Tokens opacos, almacenados como hash.
- Ubicación exacta cifrada con AES-256-GCM.
- Revocación inmediata.
- Límite de respondedores.
- Rate limiting por actor y por IP para el endpoint público.
- Auditoría sin coordenadas exactas ni tokens.
- Retención y borrado automáticos.
- Sin dependencia de billing ni analytics.