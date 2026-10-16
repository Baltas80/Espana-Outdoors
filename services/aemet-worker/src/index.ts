export interface Env {
  AEMET_API_KEY: string;
  AEMET_API_KEY_EXPIRES_AT: string;
  AEMET_BASE_URL?: string;
  OIDC_ISSUER: string;
  OIDC_AUDIENCE: string;
  OIDC_REQUIRED_ROLE: string;
  OIDC_JWKS_URL: string;
}

const LICENSE_URL = "https://www.aemet.es/es/datos_abiertos/AEMET_OpenData";
const SOURCE = "AEMET OpenData";
const MAX_UPSTREAM_BYTES = 2 * 1024 * 1024;
const MAX_TOKEN_LENGTH = 12_000;
const JWKS_CACHE_MS = 10 * 60_000;
let jwksCache: { url: string; expires: number; keys: JsonWebKey[] } | undefined;

type JsonObject = Record<string, unknown>;

function json(body: unknown, status = 200, extra: HeadersInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store",
      "x-content-type-options": "nosniff", "referrer-policy": "no-referrer", ...extra },
  });
}

function validExpiry(value: string | undefined, now = Date.now()): number | null {
  if (!value || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/.test(value)) return null;
  const time = Date.parse(value);
  return Number.isFinite(time) && time > now ? time : null;
}

function validMunicipalityCode(value: string | null): value is string {
  return value !== null && /^\d{5}$/.test(value);
}

function validForecastDate(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (m) {
    const d = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3])));
    if (d.toISOString().slice(0, 10) === value) return value;
  }
  const t = Date.parse(value);
  if (!Number.isFinite(t)) return null;
  return new Date(t).toISOString().slice(0, 10);
}

function b64url(input: string): Uint8Array {
  const padded = input.replace(/-/g, "+").replace(/_/g, "/") + "=".repeat((4 - input.length % 4) % 4);
  const raw = atob(padded);
  return Uint8Array.from(raw, c => c.charCodeAt(0));
}

function decodePart(part: string): JsonObject {
  const parsed: unknown = JSON.parse(new TextDecoder().decode(b64url(part)));
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("invalid token part");
  return parsed as JsonObject;
}

async function loadJwks(url: string): Promise<JsonWebKey[]> {
  if (jwksCache?.url === url && jwksCache.expires > Date.now()) return jwksCache.keys;
  const parsed = new URL(url);
  if (parsed.protocol !== "https:") throw new Error("JWKS URL must use HTTPS");
  const response = await fetch(parsed, { headers: { accept: "application/json" }, redirect: "error", signal: AbortSignal.timeout(4000) });
  if (!response.ok) throw new Error("JWKS unavailable");
  const doc: unknown = await response.json();
  if (!doc || typeof doc !== "object" || !Array.isArray((doc as { keys?: unknown }).keys)) throw new Error("invalid JWKS");
  const keys = (doc as { keys: JsonWebKey[] }).keys.filter(k => k.kty === "RSA" && k.alg !== "HS256" && typeof k.kid === "string" && k.use !== "enc");
  if (!keys.length) throw new Error("no compatible signing keys");
  jwksCache = { url, keys, expires: Date.now() + JWKS_CACHE_MS };
  return keys;
}

export async function authenticate(request: Request, env: Env, nowSeconds = Math.floor(Date.now() / 1000)): Promise<{ sub: string } | null> {
  const header = request.headers.get("authorization") ?? "";
  const match = /^Bearer ([A-Za-z0-9._~-]+)$/.exec(header);
  if (!match || match[1].length > MAX_TOKEN_LENGTH) return null;
  try {
    const [encodedHeader, encodedClaims, encodedSignature, extra] = match[1].split(".");
    if (!encodedHeader || !encodedClaims || !encodedSignature || extra !== undefined) return null;
    const headerData = decodePart(encodedHeader);
    const claims = decodePart(encodedClaims);
    if (headerData.alg !== "RS256" || typeof headerData.kid !== "string") return null;
    const issuer = env.OIDC_ISSUER.replace(/\/$/, "");
    if (!issuer.startsWith("https://") || claims.iss !== issuer) return null;
    const aud = claims.aud;
    if (!(aud === env.OIDC_AUDIENCE || (Array.isArray(aud) && aud.includes(env.OIDC_AUDIENCE)))) return null;
    if (typeof claims.exp !== "number" || claims.exp <= nowSeconds) return null;
    if (typeof claims.nbf === "number" && claims.nbf > nowSeconds) return null;
    if (typeof claims.iat === "number" && claims.iat > nowSeconds + 60) return null;
    if (typeof claims.sub !== "string" || claims.sub.length < 1 || claims.sub.length > 256) return null;
    const access = claims.resource_access;
    if (!access || typeof access !== "object" || Array.isArray(access)) return null;
    const client = (access as Record<string, unknown>)[env.OIDC_AUDIENCE];
    if (!client || typeof client !== "object" || Array.isArray(client)) return null;
    const roles = (client as Record<string, unknown>).roles;
    if (!Array.isArray(roles) || !roles.includes(env.OIDC_REQUIRED_ROLE)) return null;

    const keys = await loadJwks(env.OIDC_JWKS_URL);
    const jwk = keys.find(k => k.kid === headerData.kid);
    if (!jwk) { jwksCache = undefined; return null; }
    const key = await crypto.subtle.importKey("jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"]);
    const valid = await crypto.subtle.verify({ name: "RSASSA-PKCS1-v1_5" }, key, b64url(encodedSignature), new TextEncoder().encode(encodedHeader + "." + encodedClaims));
    return valid ? { sub: claims.sub } : null;
  } catch {
    return null;
  }
}

async function upstreamJSON(url: string, apiKey?: string): Promise<unknown> {
  const response = await fetch(url, {
    headers: { accept: "application/json", ...(apiKey ? { api_key: apiKey } : {}) },
    redirect: "error",
    signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) throw new Error("AEMET upstream unavailable");
  const text = await response.text();
  if (new TextEncoder().encode(text).byteLength > MAX_UPSTREAM_BYTES) throw new Error("AEMET response too large");
  return JSON.parse(text);
}

function number(parent: unknown, key: string): number | null {
  if (!parent || typeof parent !== "object") return null;
  const value = Number((parent as Record<string, unknown>)[key]);
  return Number.isFinite(value) ? value : null;
}

function firstNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (Array.isArray(value) && value.length) {
    const item = value[0];
    if (item && typeof item === "object") {
      const obj = item as Record<string, unknown>;
      const v = firstNumber(obj.valor ?? obj.value ?? obj.velocidad);
      if (v !== null) return v;
    }
    return firstNumber(item);
  }
  return null;
}

function condition(value: unknown): string {
  const first = Array.isArray(value) ? value[0] : null;
  const text = first && typeof first === "object" ? String((first as Record<string, unknown>).descripcion ?? "").toLowerCase() : "";
  if (text.includes("torment")) return "storm";
  if (text.includes("nieve")) return "snow";
  if (text.includes("lluv") || text.includes("precipit")) return "rain";
  if (text.includes("niebla")) return "fog";
  if (text.includes("nub") && text.includes("poco")) return "partlyCloudy";
  if (text.includes("nub")) return "cloudy";
  if (text.includes("despej")) return "clear";
  return "unknown";
}

function normalizeForecast(payload: unknown): JsonObject[] {
  if (!payload || typeof payload !== "object") throw new Error("invalid AEMET forecast");
  const pred = (payload as JsonObject).prediccion;
  if (!pred || typeof pred !== "object") throw new Error("forecast missing prediccion");
  const days = (pred as JsonObject).dia;
  if (!Array.isArray(days)) throw new Error("forecast missing days");
  const out: JsonObject[] = [];
  for (const raw of days) {
    if (!raw || typeof raw !== "object") continue;
    const day = raw as JsonObject;
    const date = validForecastDate(day.fecha);
    if (!date) continue;
    out.push({
      date, condition: condition(day.estadoCielo),
      min: number(day.temperatura, "minima"), max: number(day.temperatura, "maxima"),
      precipitationProbability: firstNumber(day.probPrecipitacion),
      precipitationMm: firstNumber(day.precipitacion),
      windSpeed: firstNumber(day.viento), windDirection: null,
    });
  }
  if (!out.length) throw new Error("AEMET returned no usable forecast days");
  return out;
}

function errorStatus(error: unknown): number {
  const message = error instanceof Error ? error.message : "";
  return message.includes("expired") || message.includes("not configured") ? 503 : 502;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method !== "GET") return json({ error: "method not allowed" }, 405, { allow: "GET" });
    if (url.pathname === "/healthz") return json({ status: "ok", provider: "aemet-weather" });
    if (url.pathname !== "/v1/sources/aemet-weather" && url.pathname !== "/v1/sources/aemet-weather/health") return json({ error: "not found" }, 404);

    const identity = await authenticate(request, env);
    if (!identity) return json({ error: "unauthorized" }, 401, { "www-authenticate": "Bearer" });

    if (url.pathname.endsWith("/health")) {
      return json({ kind: "official", status: validExpiry(env.AEMET_API_KEY_EXPIRES_AT) ? "healthy" : "unavailable",
        observedAt: new Date().toISOString(), licenseUrl: LICENSE_URL, attribution: SOURCE,
        ...(validExpiry(env.AEMET_API_KEY_EXPIRES_AT) ? { expiresAt: new Date(validExpiry(env.AEMET_API_KEY_EXPIRES_AT)!).toISOString() } : {}) });
    }

    const municipalityCode = url.searchParams.get("municipalityCode");
    if (!validMunicipalityCode(municipalityCode)) return json({ error: "municipalityCode must be a five-digit code" }, 400);
    if (!env.AEMET_API_KEY?.trim()) return json({ error: "official source unavailable" }, 503);
    if (!validExpiry(env.AEMET_API_KEY_EXPIRES_AT)) return json({ error: "official source unavailable" }, 503);

    try {
      const base = (env.AEMET_BASE_URL || "https://opendata.aemet.es/opendata/api").replace(/\/$/, "");
      if (!base.startsWith("https://opendata.aemet.es/")) return json({ error: "invalid upstream configuration" }, 503);
      const metadata = await upstreamJSON(base + "/prediccion/especifica/municipio/diaria/" + municipalityCode, env.AEMET_API_KEY) as JsonObject;
      if (typeof metadata.datos !== "string") throw new Error("invalid AEMET metadata");
      const dataURL = new URL(metadata.datos);
      if (dataURL.protocol !== "https:" || dataURL.hostname !== "opendata.aemet.es" || dataURL.username || dataURL.password) throw new Error("rejected AEMET data URL");
      const data = normalizeForecast(await upstreamJSON(dataURL.toString()));
      const now = new Date().toISOString();
      return json({ data, provenance: { source: SOURCE, licenseUrl: LICENSE_URL, observedAt: now },
        freshness: { status: "current", fetchedAt: now } }, 200, { "cache-control": "private, max-age=60" });
    } catch (error) {
      return json({ error: "official source unavailable" }, errorStatus(error));
    }
  },
};
