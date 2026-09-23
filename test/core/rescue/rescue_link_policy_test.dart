import 'package:espana_outdoors/core/contracts/platform_services.dart';
import 'package:espana_outdoors/core/rescue/rescue_link_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('volunteer offers are blocked in hazardous contexts', () {
    const policy = RescueLinkPolicy();
    expect(
      policy.canOfferVolunteer(
        inFireZone: true,
        underEvacuation: false,
        routeClosed: false,
        severeOfficialAlert: false,
      ),
      isFalse,
    );
    expect(
      policy.canOfferVolunteer(
        inFireZone: false,
        underEvacuation: false,
        routeClosed: false,
        severeOfficialAlert: false,
      ),
      isTrue,
    );
  });

  test('initial discovery never exposes exact location', () {
    const policy = RescueLinkPolicy();
    expect(policy.initialVisibility, LocationPrivacy.approximate);
    expect(
      policy.visibilityAfterAcceptance(RescueRole.volunteer),
      LocationPrivacy.approximate,
    );
    expect(
      policy.visibilityAfterAcceptance(RescueRole.verifiedProfessional),
      LocationPrivacy.temporary,
    );
  });
}
