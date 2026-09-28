#!/usr/bin/env python3
"""
Build the public España Outdoor route catalog from official CNIG listing pages.

This is a catalog/discovery layer: it indexes official downloadable route records.
Geometry/GPX parsing stays in a later data-ingestion pipeline.
"""
from __future__ import annotations

import html
import json
import re
import ssl
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "site" / "data" / "routes-catalog.json"

SOURCES = [
    {
        "id": "fedme",
        "name": "Senderos FEDME — CNIG",
        "listing_url": "https://centrodedescargas.cnig.es/CentroDescargas/senderos-fedme-kml.do",
        "catalog_url": "https://centrodedescargas.cnig.es/CentroDescargas/senderos-fedme",
        "license": "CC BY 4.0 FEDME",
    },
    {
        "id": "caminos-naturales",
        "name": "Caminos Naturales — CNIG",
        "listing_url": "https://centrodedescargas.cnig.es/CentroDescargas/caminos-naturales-kml",
        "catalog_url": "https://centrodedescargas.cnig.es/CentroDescargas/caminos-naturales",
        "license": "CC BY 4.0 MAPA",
    },
    {
        "id": "parques-nacionales",
        "name": "Rutas de Parques Nacionales — CNIG",
        "listing_url": "https://centrodedescargas.cnig.es/CentroDescargas/loadParquesNac",
        "catalog_url": "https://centrodedescargas.cnig.es/CentroDescargas/listadoParquesNac",
        "license": None,
    },
]

USER_AGENT = "EspanaOutdoorRouteCatalog/1.0 (+https://espanaoutdoor.es/)"
TIMEOUT = 25


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    context = ssl.create_default_context()
    with urllib.request.urlopen(req, timeout=TIMEOUT, context=context) as response:
        raw = response.read()
        charset = response.headers.get_content_charset() or "utf-8"
        return raw.decode(charset, errors="replace")


def clean_filename(value: str) -> str:
    value = html.unescape(value)
    value = urllib.parse.unquote(value)
    value = re.sub(r"[_]+", " ", value)
    value = re.sub(r"\s+", " ", value).strip()
    return value


def classify_fedme(name: str) -> tuple[str, str]:
    low = name.lower()
    if re.search(r"(^|[-_\s])gr([-\s_]|$)", low):
        return "GR", "Gran Recorrido"
    if re.search(r"(^|[-_\s])pr([-\s_]|$)", low):
        return "PR", "Pequeño Recorrido"
    if re.search(r"(^|[-_\s])sl([-\s_]|$)", low):
        return "SL", "Sendero Local"
    return "FEDME", "Sendero FEDME"


def slug(value: str) -> str:
    value = re.sub(r"[^a-z0-9]+", "-", value.lower())
    return value.strip("-")[:100]


def extract_links(page: str, base_url: str) -> list[dict[str, str | None]]:
    # Intentionally tolerant: CNIG pages have changed markup over time.
    pattern = re.compile(
        r'<a\b[^>]*href=["\']([^"\']+\.kml(?:\?[^"\']*)?)["\'][^>]*>(.*?)</a>',
        re.I | re.S,
    )
    records = []
    seen = set()
    for href, label in pattern.findall(page):
        url = urllib.parse.urljoin(base_url, html.unescape(href))
        filename = urllib.parse.unquote(url.rsplit("/", 1)[-1].split("?", 1)[0])
        key = url.lower()
        if key in seen:
            continue
        seen.add(key)
        text_label = re.sub(r"<[^>]+>", " ", label)
        text_label = re.sub(r"\s+", " ", html.unescape(text_label)).strip()
        records.append({"url": url, "filename": filename, "label": text_label})
    return records


def build_source(source: dict) -> list[dict]:
    page = fetch(source["listing_url"])
    links = extract_links(page, source["listing_url"])
    routes: list[dict] = []

    if not links:
        # Some CNIG versions render the KML names as text without a direct href.
        # Keep the catalog usable by indexing those filenames and linking back
        # to the official listing page.
        names = sorted(set(re.findall(r"(?i)[A-Za-z0-9][A-Za-z0-9_.-]{4,}\.kml", page)))
        links = [
            {"url": None, "filename": name, "label": name}
            for name in names
        ]

    for item in links:
        filename = clean_filename(item["filename"])
        name = clean_filename(item["label"]) if item["label"] else filename
        name = re.sub(r"\.kml$", "", name, flags=re.I)

        route_type = "CN"
        type_label = "Camino Natural"
        if source["id"] == "fedme":
            route_type, type_label = classify_fedme(filename)
        elif source["id"] == "parques-nacionales":
            route_type, type_label = "PN", "Ruta de Parque Nacional"

        routes.append(
            {
                "id": f'{source["id"]}-{slug(filename[:-4])}',
                "name": name,
                "code": filename[:-4],
                "locality": "",
                "province": "",
                "community": "",
                "type": route_type,
                "type_label": type_label,
                "loop": None,
                "distance_km": None,
                "duration": None,
                "ascent_m": None,
                "descent_m": None,
                "source_id": source["id"],
                "source_name": source["name"],
                "source_url": source["listing_url"],
                "catalog_url": source["catalog_url"],
                "download_url": item.get("url"),
                "license": source["license"],
                "geometry_status": "catalog-only",
            }
        )
    return routes


def load_existing() -> dict:
    if not OUT.exists():
        return {"routes": []}
    try:
        return json.loads(OUT.read_text(encoding="utf-8"))
    except Exception:
        return {"routes": []}


def main() -> None:
    existing = load_existing()
    baseline = [
        item for item in existing.get("routes", [])
        if item.get("source_id") not in {"fedme", "caminos-naturales", "parques-nacionales"}
    ]

    all_routes = list(baseline)
    source_stats = []

    for source in SOURCES:
        try:
            parsed = build_source(source)
        except Exception as exc:
            parsed = []
            source_stats.append(
                {
                    "id": source["id"],
                    "status": "fallback",
                    "error": str(exc),
                    "records": 0,
                }
            )

        # Do not delete a previously generated source catalog when CNIG is
        # temporarily unavailable or changes its HTML layout.
        if parsed:
            all_routes.extend(parsed)
            source_stats.append(
                {"id": source["id"], "status": "updated", "records": len(parsed)}
            )
        else:
            source_stats.append(
                {"id": source["id"], "status": "kept-existing", "records": 0}
            )

    dedup = {}
    for route in all_routes:
        dedup[route["id"]] = route
    all_routes = list(dedup.values())

    payload = {
        "version": "1.0.0",
        "generated_at": date.today().isoformat(),
        "scope": "official-catalog-index",
        "note": (
            "Índice público de recorridos y ficheros oficiales de CNIG. "
            "Esta capa aporta descubrimiento y enlaces a la fuente; la geometría "
            "normalizada y la navegación se incorporarán en la siguiente fase."
        ),
        "source_stats": source_stats,
        "sources": SOURCES,
        "routes": all_routes,
    }

    OUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"Generated {len(all_routes)} route records")
    for stat in source_stats:
        print(stat)


if __name__ == "__main__":
    main()
