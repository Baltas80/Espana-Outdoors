import { describe, expect, it } from "vitest";
import { authenticate, normalizeForecast, validExpiry, validForecastDate, validMunicipalityCode } from "../src/index";

const env = {
  AEMET_API_KEY: "not-a-real-key",
  AEMET_API_KEY_EXPIRES_AT: "2099-01-01T00:00:00Z",
  OIDC_ISSUER: "https://identity.example.test/realms/outdoor",
  OIDC_AUDIENCE: "outdoor-mobile",
  OIDC_REQUIRED_ROLE: "source.read",
  OIDC_JWKS_URL: "https://identity.example.test/realms/outdoor/protocol/openid-connect/certs",
};

describe("configuration and date validation", () => {
  it("requires a future RFC3339 key expiry", () => {
    expect(validExpiry("2099-01-01T00:00:00Z", Date.parse("2026-01-01T00:00:00Z"))).not.toBeNull();
    expect(validExpiry("2001-01-01T00:00:00Z", Date.parse("2026-01-01T00:00:00Z"))).toBeNull();
    expect(validExpiry("not-a-date", 0)).toBeNull();
    expect(validExpiry("2026-01-01", 0)).toBeNull();
  });

  it("accepts only five-digit municipality codes", () => {
    expect(validMunicipalityCode("03099")).toBe(true);
    expect(validMunicipalityCode("3099")).toBe(false);
    expect(validMunicipalityCode("03A99")).toBe(false);
    expect(validMunicipalityCode(null)).toBe(false);
  });

  it("rejects impossible calendar dates and normalizes valid timestamps", () => {
    expect(validForecastDate("2026-02-28")).toBe("2026-02-28");
    expect(validForecastDate("2026-02-30")).toBeNull();
    expect(validForecastDate("garbage")).toBeNull();
    expect(validForecastDate("2026-10-16T23:00:00+02:00")).toBe("2026-10-16");
  });

  it("normalizes the existing AEMET daily forecast item shape", () => {
    const rows = normalizeForecast({ prediccion: { dia: [{
      fecha: "2026-10-16",
      estadoCielo: [{ descripcion: "Nuboso" }],
      temperatura: { minima: 9, maxima: 19 },
      probPrecipitacion: [{ valor: 35 }],
      precipitacion: [{ valor: 1.2 }],
      viento: [{ velocidad: [12], direccion: ["NO"] }],
    }] } });
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      date: "2026-10-16", condition: "cloudy", min: 9, max: 19,
      precipitationProbability: 35, precipitationMm: 1.2, windSpeed: 12,
    });
  });

  it("rejects malformed upstream payloads instead of treating them as forecast data", () => {
    expect(() => normalizeForecast({ prediccion: { dia: [{ fecha: "2026-02-30" }] } })).toThrow();
  });
});

describe("authentication fail-closed behavior", () => {
  it("rejects missing bearer tokens", async () => {
    const request = new Request("https://worker.test/v1/sources/aemet-weather");
    await expect(authenticate(request, env)).resolves.toBeNull();
  });

  it("rejects malformed bearer tokens without calling an identity provider", async () => {
    const request = new Request("https://worker.test/v1/sources/aemet-weather", {
      headers: { authorization: "Bearer not.a.valid.jwt" },
    });
    await expect(authenticate(request, env)).resolves.toBeNull();
  });
});
