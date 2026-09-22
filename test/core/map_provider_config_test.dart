import 'package:espana_outdoors/features/map/map_provider_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default map provider keeps attribution and a stable app user agent', () {
    const provider = MapProviderConfig.openStreetMap;

    expect(provider.tileUrlTemplate, contains('{z}/{x}/{y}.png'));
    expect(provider.attribution, contains('OpenStreetMap contributors'));
    expect(provider.userAgent, startsWith('EspanaOutdoor/'));
  });
}
