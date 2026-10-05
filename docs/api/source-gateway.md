# Source Gateway contract

The mobile/web client does not call AEMET, MITECO, IGN/CNIG or emergency providers with provider credentials. The first-party Source Gateway performs provider authentication, normalization, attribution and freshness checks.

## Health

`GET /v1/sources/{sourceId}/health`

```json
{
  "kind": "official",
  "status": "healthy",
  "observedAt": "2026-09-23T12:00:00Z",
  "expiresAt": "2026-09-23T13:00:00Z",
  "licenseUrl": "https://example.invalid/license",
  "attribution": "Source attribution"
}
```

Allowed `kind`: `official`, `community`, `derived`.

Allowed `status`: `healthy`, `degraded`, `unavailable`, `stale`.

## Data

`GET /v1/sources/{sourceId}`

Query parameters are source-specific but must never contain provider secrets.

The response is a single JSON envelope. A top-level JSON array is invalid and must be rejected by clients.

```json
{
  "data": [],
  "provenance": {
    "source": "AEMET OpenData",
    "licenseUrl": "https://example.invalid/license",
    "observedAt": "2026-09-23T12:00:00Z"
  },
  "freshness": {
    "status": "current",
    "fetchedAt": "2026-09-23T12:00:00Z"
  }
}
```

The data envelope has no additional top-level fields. Its `provenance` and `freshness` objects also reject unknown fields. The generic gateway contract requires each data item to be a JSON object; the item fields remain source-specific and are validated by the corresponding source adapter.

## Alerts normalized record

`GET /v1/sources/alerts`

```json
{
  "data": [
    {
      "id": "stable-provider-id",
      "title": "Example alert",
      "level": "yellow",
      "kind": "ALERTA_OFICIAL",
      "source": "AEMET",
      "description": "Provider-supplied explanation",
      "updatedAt": "2026-09-23T12:00:00Z",
      "expiresAt": "2026-09-23T18:00:00Z",
      "certainty": "high"
    }
  ]
}
```

The gateway must reject or quarantine malformed upstream records instead of passing them through as trusted information.

## Schema enforcement

The public contract is intentionally closed: unknown fields, legacy top-level array responses, missing provenance/freshness metadata and invalid freshness states are rejected by the Flutter gateway client. The server must emit only the documented envelope.

The machine-readable generic contract is `docs/api/source-gateway.schema.json`.

## Security requirements

- Provider API keys stay server-side.
- No emergency exact location is sent to upstream providers unless explicitly required and authorized.
- Source responses are cached with source-specific TTLs and stale-state semantics.
- Every transformation preserves provenance.
- The gateway must fail closed for missing critical metadata.
- Rate limiting, request authentication, audit logging and abuse controls belong at the gateway/backend layer.
