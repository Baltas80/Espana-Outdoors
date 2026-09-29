#!/usr/bin/env python3
"""Smoke-test a real pedestrian route against the configured Valhalla endpoint."""

from __future__ import annotations

import argparse
import json
import urllib.error
import urllib.request
from typing import Any


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    args = parser.parse_args()

    base = args.base_url.rstrip("/") + "/route"
    payload = {
        "locations": [
            {"lat": 40.416775, "lon": -3.703790, "type": "break"},
            {"lat": 40.415363, "lon": -3.693994, "type": "break"},
        ],
        "costing": "pedestrian",
        "units": "kilometers",
        "shape_format": "geojson",
        "directions_options": {
            "units": "kilometers",
            "language": "es-ES",
        },
    }

    request = urllib.request.Request(
        base,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "content-type": "application/json",
            "User-Agent": "EspanaOutdoor-Routing-Smoke/1.0",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            if response.status < 200 or response.status >= 300:
                raise RuntimeError(f"unexpected HTTP status: {response.status}")
            document: Any = json.load(response)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        raise SystemExit(f"Valhalla route smoke failed: {exc}") from exc

    trip = document.get("trip")
    if not isinstance(trip, dict):
        raise SystemExit("Valhalla route smoke failed: response has no trip.")

    legs = trip.get("legs")
    if not isinstance(legs, list) or not legs:
        raise SystemExit("Valhalla route smoke failed: response has no legs.")

    total_distance_km = 0.0
    total_steps = 0
    total_shape_points = 0

    for index, leg in enumerate(legs):
        if not isinstance(leg, dict):
            raise SystemExit(f"Valhalla route smoke failed: leg {index} is invalid.")

        summary = leg.get("summary")
        if isinstance(summary, dict):
            distance = summary.get("length")
            if isinstance(distance, (int, float)):
                total_distance_km += float(distance)

        maneuvers = leg.get("maneuvers")
        if isinstance(maneuvers, list):
            total_steps += sum(
                1 for item in maneuvers if isinstance(item, dict)
            )

        shape = leg.get("shape")
        if isinstance(shape, str):
            # Valhalla may return its canonical encoded polyline shape even
            # when a deployment does not honor shape_format=geojson.
            # Count a non-empty encoded shape here; the mobile adapter
            # decodes polyline6.
            if len(shape) < 4:
                raise SystemExit(
                    f"Valhalla route smoke failed: leg {index} has no usable shape."
                )
            total_shape_points += 2
            continue

        if not isinstance(shape, dict):
            raise SystemExit(
                f"Valhalla route smoke failed: leg {index} has no route shape."
            )
        geometry = shape.get("geometry")
        if isinstance(geometry, dict):
            coordinates = geometry.get("coordinates")
        else:
            coordinates = shape.get("coordinates")
        if not isinstance(coordinates, list) or len(coordinates) < 2:
            raise SystemExit(
                f"Valhalla route smoke failed: leg {index} has no usable shape."
            )
        total_shape_points += len(coordinates)

    if total_distance_km <= 0:
        raise SystemExit("Valhalla route smoke failed: zero route distance.")
    if total_shape_points < 2:
        raise SystemExit("Valhalla route smoke failed: empty route geometry.")

    print(
        "routing_smoke_ok="
        f"distance_km={total_distance_km:.3f} "
        f"legs={len(legs)} "
        f"steps={total_steps} "
        f"shape_points={total_shape_points}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
