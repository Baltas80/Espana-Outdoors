"""Unit tests for the Geofabrik Spain source URL release gate."""

import unittest

from validate_geofabrik_spain_url import validation_error


class GeofabrikSpainUrlTests(unittest.TestCase):
    def test_accepts_dated_snapshot(self) -> None:
        self.assertIsNone(
            validation_error(
                "https://download.geofabrik.de/europe/spain-261012.osm.pbf"
            )
        )

    def test_rejects_mutable_latest_extract(self) -> None:
        error = validation_error(
            "https://download.geofabrik.de/europe/spain-latest.osm.pbf"
        )
        self.assertIsNotNone(error)
        self.assertIn("dated Spain snapshot", error)

    def test_rejects_non_https(self) -> None:
        self.assertIsNotNone(
            validation_error(
                "http://download.geofabrik.de/europe/spain-261012.osm.pbf"
            )
        )

    def test_rejects_non_geofabrik_host(self) -> None:
        self.assertIsNotNone(
            validation_error("https://example.com/europe/spain-261012.osm.pbf")
        )

    def test_rejects_wrong_region_or_path(self) -> None:
        self.assertIsNotNone(
            validation_error(
                "https://download.geofabrik.de/europe/spain/andalucia-latest.osm.pbf"
            )
        )

    def test_rejects_invalid_calendar_date(self) -> None:
        self.assertIsNotNone(
            validation_error(
                "https://download.geofabrik.de/europe/spain-261332.osm.pbf"
            )
        )

    def test_rejects_query_and_fragment(self) -> None:
        self.assertIsNotNone(
            validation_error(
                "https://download.geofabrik.de/europe/spain-261012.osm.pbf?mirror=1"
            )
        )
        self.assertIsNotNone(
            validation_error(
                "https://download.geofabrik.de/europe/spain-261012.osm.pbf#latest"
            )
        )

    def test_rejects_userinfo_and_unexpected_port(self) -> None:
        self.assertIsNotNone(
            validation_error(
                "https://user@download.geofabrik.de/europe/spain-261012.osm.pbf"
            )
        )
        self.assertIsNotNone(
            validation_error(
                "https://download.geofabrik.de:8443/europe/spain-261012.osm.pbf"
            )
        )


if __name__ == "__main__":
    unittest.main()
