enum DestinationCoordinateAxis { latitude, longitude }

final class DestinationCoordinateValidation {
  const DestinationCoordinateValidation.valid(this.value) : errorMessage = null;

  const DestinationCoordinateValidation.invalid(this.errorMessage)
    : value = null;

  final double? value;
  final String? errorMessage;

  bool get isValid => value != null;
}

DestinationCoordinateValidation validateDestinationCoordinate(
  String? rawValue, {
  required DestinationCoordinateAxis axis,
}) {
  final coordinateName = axis == DestinationCoordinateAxis.latitude
      ? 'latitud'
      : 'longitud';
  final input = rawValue?.trim() ?? '';
  if (input.isEmpty) {
    return DestinationCoordinateValidation.invalid(
      'Introduce la $coordinateName.',
    );
  }

  if (input.contains(',') && input.contains('.')) {
    return const DestinationCoordinateValidation.invalid(
      'Usa coma o punto decimal, no ambos.',
    );
  }

  final value = double.tryParse(input.replaceAll(',', '.'));
  if (value == null || !value.isFinite) {
    return DestinationCoordinateValidation.invalid(
      'Introduce la $coordinateName como número decimal.',
    );
  }

  final maximum = axis == DestinationCoordinateAxis.latitude ? 90.0 : 180.0;
  if (value < -maximum || value > maximum) {
    return DestinationCoordinateValidation.invalid(
      'La $coordinateName debe estar entre −${maximum.toStringAsFixed(0)} y ${maximum.toStringAsFixed(0)}.',
    );
  }

  return DestinationCoordinateValidation.valid(value);
}
