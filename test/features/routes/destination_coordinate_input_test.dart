import 'package:espana_outdoors/features/routes/destination_coordinate_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateDestinationCoordinate', () {
    test('accepts decimal commas, whitespace, and signed values', () {
      final latitude = validateDestinationCoordinate(
        ' 40,4168 ',
        axis: DestinationCoordinateAxis.latitude,
      );
      final longitude = validateDestinationCoordinate(
        '-3,7038',
        axis: DestinationCoordinateAxis.longitude,
      );

      expect(latitude.isValid, isTrue);
      expect(latitude.value, 40.4168);
      expect(longitude.isValid, isTrue);
      expect(longitude.value, -3.7038);
    });

    test('accepts the inclusive latitude and longitude boundaries', () {
      for (final value in ['-90', '90']) {
        expect(
          validateDestinationCoordinate(
            value,
            axis: DestinationCoordinateAxis.latitude,
          ).isValid,
          isTrue,
          reason: 'Latitude $value is valid.',
        );
      }

      for (final value in ['-180', '180']) {
        expect(
          validateDestinationCoordinate(
            value,
            axis: DestinationCoordinateAxis.longitude,
          ).isValid,
          isTrue,
          reason: 'Longitude $value is valid.',
        );
      }
    });

    test('reports required fields', () {
      expect(
        validateDestinationCoordinate(
          '  ',
          axis: DestinationCoordinateAxis.latitude,
        ).errorMessage,
        'Introduce la latitud.',
      );
      expect(
        validateDestinationCoordinate(
          null,
          axis: DestinationCoordinateAxis.longitude,
        ).errorMessage,
        'Introduce la longitud.',
      );
    });

    test('rejects malformed and non-finite numbers', () {
      for (final value in ['abc', 'NaN', 'Infinity', '-Infinity', '40,4.2']) {
        final result = validateDestinationCoordinate(
          value,
          axis: DestinationCoordinateAxis.latitude,
        );

        expect(result.isValid, isFalse, reason: '$value must be rejected.');
        expect(
          result.errorMessage,
          isNotNull,
          reason: '$value must explain the error.',
        );
      }
    });

    test('rejects values outside each axis range', () {
      final latitude = validateDestinationCoordinate(
        '90.0001',
        axis: DestinationCoordinateAxis.latitude,
      );
      final longitude = validateDestinationCoordinate(
        '-180.0001',
        axis: DestinationCoordinateAxis.longitude,
      );

      expect(latitude.errorMessage, 'La latitud debe estar entre −90 y 90.');
      expect(
        longitude.errorMessage,
        'La longitud debe estar entre −180 y 180.',
      );
    });
  });
}
