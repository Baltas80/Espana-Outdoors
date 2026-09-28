#!/usr/bin/env python3
"""
Build a small, cacheable MITECO data catalog for the public website.

The site does not call the MITECO API on every browser request. GitHub Actions
refreshes this JSON at deploy time, keeping the frontend fast and resilient.
"""
from __future__ import annotations

import json
import ssl
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "site" / "data" / "miteco-catalog.json"

API_BASE = "https://catalogo.datosabiertos.miteco.gob.es/catalogo/api/3/action"
USER_AGENT = "EspanaOutdoorMitecoCatalog/1.0 (+https://espanaoutdoor.es/)"
TIMEOUT = 25

SEED_DATASETS = [
    {
        "id": "fc21c1a5-4c02-4157-9d2f-9a2cd200f908",
        "title": "Distribución de especies",
        "description": "Cartografía de distribución de especies silvestres terrestres y marinas presentes en España según EIDOS/MITECO.",
        "catalog_url": "https://catalogo.datosabiertos.miteco.gob.es/catalogo/es/dataset/fc21c1a5-4c02-4157-9d2f-9a2cd200f908",
        "resources": [
            {
                "name": "Servicio WMS Distribución de especies",
                "format": "WMS",
                "url": "https://wms.mapama.gob.es/sig/Biodiversidad/SD_EIDOS",
            }
        ],
    }
]

QUERIES = [
    "Distribución de especies EIDOS",
    "Atlas de los Paisajes de España",
    "Espacios Naturales Protegidos",
]


def fetch_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    context = ssl.create_default_context()
    with urllib.request.urlopen(req, timeout=TIMEOUT, context=context) as response:
        charset = response.headers.get_content_charset() or "utf-8"
        return json.loads(response.read().decode(charset, errors="replace"))


def package_search(query: str) -> list[dict]:
    url = API_BASE + "/package_search?" + urllib.parse.urlencode({"q": query, "rows": 12})
    payload = fetch_json(url)
    if not payload.get("success"):
        raise RuntimeError("MITECO package_search returned success=false")
    return payload.get("result", {}).get("results", [])


def compact_package(item: dict) -> dict:
    resources = []
    for resource in item.get("resources", []) or []:
        resources.append(
            {
                "name": resource.get("name") or resource.get("description") or "Recurso",
                "format": resource.get("format"),
                "url": resource.get("url"),
            }
        )
    return {
        "id": item.get("id"),
        "title": item.get("title") or item.get("name"),
        "notes": item.get("notes"),
        "catalog_url": (
            "https://catalogo.datosabiertos.miteco.gob.es/catalogo/es/dataset/"
            + str(item.get("id"))
        ),
        "organization": (item.get("organization") or {}).get("title"),
        "resources": resources,
    }


def load_seed() -> dict:
    if OUT.exists():
        try:
            return json.loads(OUT.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {
        "version": "1.0.0",
        "generated_at": None,
        "status": "seed",
        "source": "MITECO CKAN API",
        "api_base": API_BASE,
        "datasets": SEED_DATASETS,
    }


def main() -> None:
    datasets_by_id = {item["id"]: dict(item) for item in SEED_DATASETS}
    errors = []

    for query in QUERIES:
        try:
            for item in package_search(query):
                compact = compact_package(item)
                if compact["id"]:
                    datasets_by_id[compact["id"]] = compact
        except Exception as exc:
            errors.append({"query": query, "error": str(exc)})

    datasets = list(datasets_by_id.values())
    payload = {
        "version": "1.0.0",
        "generated_at": date.today().isoformat(),
        "status": "live" if not errors else "partial",
        "source": "MITECO CKAN API",
        "api_base": API_BASE,
        "queries": QUERIES,
        "errors": errors,
        "datasets": datasets,
    }

    # The website must remain deployable if MITECO has a transient outage.
    if errors and not any(item.get("resources") for item in datasets):
        payload = load_seed()
        payload["generated_at"] = date.today().isoformat()
        payload["status"] = "fallback"

    OUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(
        f"MITECO catalog: status={payload['status']} "
        f"datasets={len(payload.get('datasets', []))} "
        f"errors={len(payload.get('errors', []))}"
    )


if __name__ == "__main__":
    main()
