# Emergency / Rescue Link real-device gate

This checklist is the release gate for Android and iOS. It is intentionally manual because launching 112, reading real GPS/battery state and exercising platform background-location behavior require physical devices.

## 112 handoff

For each supported Android and iOS device family:

1. Disable Wi-Fi and keep the mobile radio available.
2. Open the Safety center and start the 112 flow.
3. Verify the system phone UI is opened with **112** as the target.
4. Cancel before connecting when this is a staging test environment.
5. Repeat with the device locked/unlocked as supported by the platform.
6. Record whether the handoff failed because telephony is unavailable; the app must surface the failure and never claim the call was placed.

Do not place unattended test calls to emergency services. Use the platform's approved test procedure or a non-emergency test endpoint where applicable.

## Emergency snapshot

Verify that the captured snapshot contains:

- GPS coordinates and reported accuracy;
- capture timestamp;
- battery percentage when the platform exposes it;
- altitude when available;
- connectivity state as online/offline/unknown.

Verify that normal trusted-contact SMS shares only approximate coordinates, GPS accuracy, emergency type, expiry and the local correlation code. Battery and connectivity metadata must not be added to the SMS unless explicitly required by a future policy.

## Expiry

1. Create a short-lived Rescue Link in a controlled staging environment.
2. Verify the server rejects access after expiry.
3. Verify the mobile UI removes the expired session without requiring a restart.
4. Verify revocation prevents subsequent access.
5. Verify an already-issued shared link is not treated as active after expiry.

## Failure modes

Test with:

- location services disabled;
- location permission denied/denied forever;
- poor GPS accuracy;
- no network;
- network interruption during Rescue Link creation;
- expired link;
- revoked link;
- Keycloak/OIDC unavailable;
- backend unavailable;
- low battery.

Expected behavior is fail-closed: no invented position, no invented rescue status, no fake successful dispatch and no exposure of exact location in public discovery.

## Dangerous dispatch policy

Verify that volunteer offers remain blocked when the backend policy reports fire zone, evacuation, route closure or severe official alert. Official emergency services retain priority over volunteer roles.

## Release evidence

Attach device model, OS version, app build commit, test date, scenario result and observed failure mode to the release record. Do not attach exact personal locations or emergency contact data.
