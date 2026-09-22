## Valhalla routing runtime

España Outdoor uses Valhalla as the first routing/elevation adapter candidate.

- Release: 3.9.0
- Container: ghcr.io/valhalla/valhalla:3.9.0
- Image digest (multi-arch tag): sha256:511c095b8caf393dccceb8b519ec96b6f85a0166b2288ba014a8a748acc5a63c
- License: MIT
- OSM-derived data remains subject to ODbL and its attribution requirements.

Valhalla 3.9.0 provides routing APIs, elevation, map matching and tiled data suitable for regional/offline architectures. The project publishes official container images through GHCR and the 3.9.0 release is current as of 19 September 2026.

Do not use the public demo instance as a production dependency. Production routing must run on infrastructure controlled by España Outdoor and use an explicitly documented data build/update pipeline.

Reference: https://github.com/valhalla/valhalla
