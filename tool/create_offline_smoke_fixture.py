#!/usr/bin/env python3
"""Generate a tiny valid PMTiles v3 vector archive for Android offline smoke tests."""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path


def varint(value: int) -> bytes:
    if value < 0:
        raise ValueError("varint requires a non-negative integer")
    out = bytearray()
    while value >= 0x80:
        out.append((value & 0x7F) | 0x80)
        value >>= 7
    out.append(value)
    return bytes(out)


def build_fixture() -> bytes:
    layer = (
        b"\x0a\x0ftransportation"
        b"\x78\x02"
        b"\x28\x80\x20"
    )
    tile = b"\x1a" + varint(len(layer)) + layer

    root = b"".join(
        (
            varint(2),
            varint(0),
            varint(2026),
            varint(1),
            varint(1),
            varint(len(tile)),
            varint(len(tile)),
            varint(1),
            varint(0),
        )
    )

    metadata = json.dumps(
        {
            "tilejson": "3.0.0",
            "name": "España Outdoor offline smoke",
            "format": "pbf",
            "version": "1",
            "type": "overlay",
            "minzoom": 0,
            "maxzoom": 6,
            "bounds": [-18, 35, 5, 44],
            "center": [-3.7038, 40.4168, 6],
            "vector_layers": [{"id": "test", "fields": {}}],
        },
        separators=(",", ":"),
    ).encode("utf-8")

    header = bytearray(127)
    header[0:7] = b"PMTiles"
    header[7] = 3

    root_offset = 127
    root_length = len(root)
    metadata_offset = root_offset + root_length
    metadata_length = len(metadata)
    tile_data_offset = metadata_offset + metadata_length
    tile_data_length = len(tile) * 2

    values = (
        root_offset,
        root_length,
        metadata_offset,
        metadata_length,
        0,
        0,
        tile_data_offset,
        tile_data_length,
        2,
        2,
        1,
    )
    offset = 8
    for value in values:
        struct.pack_into("<Q", header, offset, value)
        offset += 8

    header[96] = 1
    header[97] = 1
    header[98] = 1
    header[99] = 1
    header[100] = 0
    header[101] = 6
    struct.pack_into("<i", header, 102, -180000000)
    struct.pack_into("<i", header, 106, 350000000)
    struct.pack_into("<i", header, 110, 50000000)
    struct.pack_into("<i", header, 114, 440000000)
    header[118] = 6
    struct.pack_into("<i", header, 119, -37038000)
    struct.pack_into("<i", header, 123, 404168000)

    return bytes(header) + root + metadata + tile + tile


def main() -> int:
    output = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/testing/offline_smoke.pmtiles")
    output.parent.mkdir(parents=True, exist_ok=True)
    data = build_fixture()
    output.write_bytes(data)

    if len(data) < 127:
        raise SystemExit("Generated PMTiles fixture is too small.")
    if data[:7] != b"PMTiles" or data[7] != 3:
        raise SystemExit("Generated fixture has an invalid PMTiles header.")
    if int.from_bytes(data[8:16], "little") + int.from_bytes(data[16:24], "little") > 16384:
        raise SystemExit("Generated root directory is outside the 16 KiB PMTiles bootstrap window.")

    metadata_offset = int.from_bytes(data[24:32], "little")
    metadata_length = int.from_bytes(data[32:40], "little")
    json.loads(data[metadata_offset : metadata_offset + metadata_length].decode("utf-8"))
    print(f"Generated {output} ({len(data)} bytes)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
