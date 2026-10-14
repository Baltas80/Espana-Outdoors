"""Tests for the Spain offline-map catalog contract."""

from __future__ import annotations

import unittest

from validate_map_catalog import validate_catalog_payload


def _entry(region_id: str = "spain") -> dict[str, object]:
    return {
        "id": region_id,
        "name": "España" if region_id == "spain" else "Madrid",
        "description": "Mapa de prueba",
        "providerId": "approved-pmtiles-catalog",
        "licenseUrl": "https://maps.example.invalid/license",
        "attribution": "© OpenStreetMap contributors",
        "downloadUrl": f"https://maps.example.invalid/{region_id}.pmtiles",
        "sizeBytes": 1024,
        "updatedAt": "2026-10-14T00:00:00Z",
        "sha256": "a" * 64,
    }


class MapCatalogContractTests(unittest.TestCase):
    def test_valid_catalog_selects_spain_entry(self) -> None:
        result = validate_catalog_payload([_entry("madrid"), _entry("spain")])
        self.assertEqual(result["id"], "spain")

    def test_catalog_must_be_a_list(self) -> None:
        with self.assertRaisesRegex(ValueError, "JSON array"):
            validate_catalog_payload(_entry())

    def test_catalog_must_include_spain(self) -> None:
        with self.assertRaisesRegex(ValueError, "does not contain the spain entry"):
            validate_catalog_payload([_entry("madrid")])

    def test_configured_online_map_must_match_catalog(self) -> None:
        with self.assertRaisesRegex(ValueError, "does not match"):
            validate_catalog_payload(
                [_entry("spain")],
                "https://maps.example.invalid/older-version.pmtiles",
            )

    def test_matching_online_map_url_is_accepted(self) -> None:
        result = validate_catalog_payload(
            [_entry("spain")],
            "https://maps.example.invalid/spain.pmtiles",
        )
        self.assertEqual(result["id"], "spain")

    def test_catalog_requires_approved_provider_and_valid_checksum(self) -> None:
        invalid_provider = _entry()
        invalid_provider["providerId"] = "unknown-provider"
        with self.assertRaisesRegex(ValueError, "providerId"):
            validate_catalog_payload([invalid_provider])

        invalid_checksum = _entry()
        invalid_checksum["sha256"] = "invalid"
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            validate_catalog_payload([invalid_checksum])


if __name__ == "__main__":
    unittest.main()
