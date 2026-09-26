# Valhalla production smoke gate

The mobile app consumes Valhalla through the runtime `VALHALLA_BASE_URL`. Production routing is not considered verified until the real endpoint passes the manual **Valhalla production smoke test** workflow.

The gate checks:

- HTTPS endpoint;
- `/status` returns HTTP 200 and valid JSON;
- `/route` returns a usable trip with at least one leg;
- `/height` returns elevation data.

The workflow is intentionally manual and uses the GitHub Environment `routing-production`. No public/demo Valhalla endpoint is embedded in the release configuration.

The smoke-test request shapes follow Valhalla's documented `/status`, `/route`, and `/height` endpoints.