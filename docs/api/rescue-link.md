# Rescue Link API

Rescue Link es un canal de coordinación de emergencia. No sustituye al 112 ni a los servicios profesionales.

## Principios de seguridad

El cliente puede capturar la posición exacta localmente, pero la autorización, la caducidad y la revocación son responsabilidad del backend de primera parte.

La vista de descubrimiento debe exponer únicamente ubicación aproximada. La ubicación exacta o temporal solo se devuelve después de una aceptación autorizada y conforme al rol.

El token compartido es una capacidad opaca emitida por servidor. No debe contener coordenadas, identidad del usuario ni otros datos sensibles.

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

Request:

{
  "role": "trustedContact"
}

El backend aplica la política del rol y devuelve una capacidad temporal limitada.

## POST /v1/rescue-links/{id}/revoke

Revoca la sesión inmediatamente, incluso antes de su TTL.

## Controles obligatorios del backend

- Keycloak/OIDC para autenticación.
- HTTPS y HSTS.
- Tokens opacos de corta duración con lookup server-side.
- Revocación inmediata.
- Límite de respondedores por enlace.
- Rate limiting por enlace y actor.
- Auditoría sin coordenadas exactas en logs normales.
- Cifrado en reposo de coordenadas exactas.
- Retención y borrado automáticos.
- Sin dependencia de billing ni analytics.
- Nunca publicar ubicación exacta a clientes de descubrimiento anónimo.

## Estado actual

La app ya contiene el contrato RescueLinkGateway y el adaptador HTTPS.
La producción queda bloqueada hasta desplegar y probar el servicio backend real; no se simula una revocación local como si fuera una revocación remota.