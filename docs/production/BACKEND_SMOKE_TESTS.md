# Backend production smoke gates

The Source Gateway and Rescue Link services are not considered production-ready until their real HTTPS endpoints pass the manual **Backend production smoke tests** workflow.

The smoke tests intentionally use only unauthenticated service health endpoints:

- Source Gateway: `GET /healthz`
- Rescue Link: `GET /healthz`

The workflow validates HTTPS first and then requires HTTP 200 plus `{"status":"ok"}`.

No provider credentials, OIDC tokens, database credentials or production URLs are stored in the repository.