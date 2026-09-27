# Domain → Cloudflare → R2 production runbook

Status: operational preparation only. No production endpoint is declared by this document.

## Goal

Use the owned `espanaoutdoor.es` domain as the authoritative public domain for España Outdoor infrastructure, with Cloudflare DNS and a custom R2 domain for map assets.

## 1. Registrar / DNS handoff

The domain is currently registered through Hostalia. Cloudflare's full DNS setup requires the domain's authoritative nameservers to be changed at the registrar after Cloudflare assigns the zone nameservers.

Before changing nameservers:

1. Add `espanaoutdoor.es` to the correct Cloudflare account.
2. Review the DNS records Cloudflare imports/discovers.
3. Preserve any records that are actually required by the registrar/hosting service.
4. Obtain the two nameservers assigned by Cloudflare.
5. In Hostalia, replace the current nameservers with the Cloudflare-assigned pair.
6. Wait for delegation/propagation and verify DNS resolution.

Do not copy nameservers from another domain or invent values.

## 2. R2 map domain

Existing infrastructure already contains the R2 bucket configuration for the map pipeline. The production map object must not be published through `r2.dev`.

After the domain is active in the same Cloudflare account as the R2 bucket:

1. Open R2 → the production map bucket → Settings.
2. Add a dedicated custom domain/subdomain for map assets.
3. Let Cloudflare create the required DNS record.
4. Wait until the custom domain ownership and TLS status are active.
5. Publish `spain.pmtiles` only after the object is complete and its SHA-256 has been recorded.
6. Verify HTTPS byte-range behaviour (`206 Partial Content` and `Content-Range`).
7. Verify the complete object checksum independently.
8. Only then promote the resulting HTTPS URL into the production configuration.

`r2.dev` is for development/testing and must not become the production map endpoint.

## 3. Production configuration gate

The following values remain unset until the external infrastructure is verified:

- `MAP_PMTILES_URL`
- `MAP_ATTRIBUTION`
- `OFFLINE_CATALOG_URL`
- `VALHALLA_BASE_URL`
- `SOURCE_GATEWAY_BASE_URL`
- `RESCUE_LINK_BASE_URL`

No example URL in this runbook is a production value.

## 4. Verification gate

A production map release requires all of the following evidence:

- domain delegated to Cloudflare;
- custom R2 domain active;
- HTTPS succeeds;
- `spain.pmtiles` exists at the verified production location;
- HTTP range request returns `206`;
- `Content-Range` is present and correct;
- SHA-256 matches the recorded artifact;
- offline catalog references the same immutable map artifact;
- Android/iOS can download the required regional data;
- the map works after network loss.

Until these checks exist, PMTiles remains PREPARADO rather than HECHO.

## 5. Safety

Never put Cloudflare API tokens, R2 access keys, registrar credentials, or other private credentials in Git. Use the appropriate secret store/environment configuration.
