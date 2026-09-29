# Third-party components

## Agus Maps Flutter

- Project: https://github.com/agus-works/agus-maps-flutter
- Version used by España Outdoor: 0.1.17
- License: Apache License 2.0
- Purpose: Flutter integration of the native CoMaps offline vector map engine.
- Release SDK used in Android builds: `agus-maps-sdk-v0.1.17.zip`

España Outdoor uses the pre-built SDK and the Flutter plugin interfaces. The applicable Apache 2.0 license and upstream notices are retained with the dependency/release materials.

## CoMaps map data

- Project: https://github.com/comaps/comaps
- Map data consumed by Agus Maps: CoMaps MWM files.
- Download source: official CoMaps map mirrors discovered by the Agus Maps Flutter mirror service.
- España Outdoor verifies the downloaded file size and the SHA-1 value published by the CoMaps catalogue before activating a downloaded region.

## Emergency contacts dataset

- Project: https://github.com/ly2xxx/sos
- File reused: `app/src/main/assets/emergency_contacts.json`
- License: MIT
- Purpose: offline emergency-number data for the SOS module.

The emergency-number dataset is treated as a convenience/offline reference. España Outdoor must not represent third-party values as a substitute for local emergency authorities. The application's general emergency call remains subject to the destination country's applicable emergency service.
