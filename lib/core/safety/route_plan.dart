class RoutePlan {
  const RoutePlan({
    this.routeId,
    this.routeName,
    required this.departureAt,
    required this.expectedReturnAt,
    required this.participants,
    this.trustedContactId,
  });

  final String? routeId;
  final String? routeName;
  final DateTime departureAt;
  final DateTime expectedReturnAt;
  final int participants;
  final String? trustedContactId;

  bool get isValid =>
      participants >= 1 && expectedReturnAt.isAfter(departureAt);

  Map<String, dynamic> toJson() => {
        'routeId': routeId,
        'routeName': routeName,
        'departureAt': departureAt.toIso8601String(),
        'expectedReturnAt': expectedReturnAt.toIso8601String(),
        'participants': participants,
        'trustedContactId': trustedContactId,
      };

  factory RoutePlan.fromJson(Map<String, dynamic> json) {
    final departure = DateTime.tryParse('${json['departureAt'] ?? ''}');
    final expectedReturn =
        DateTime.tryParse('${json['expectedReturnAt'] ?? ''}');
    if (departure == null || expectedReturn == null) {
      throw const FormatException('Plan de ruta inválido.');
    }

    return RoutePlan(
      routeId: json['routeId']?.toString(),
      routeName: json['routeName']?.toString(),
      departureAt: departure,
      expectedReturnAt: expectedReturn,
      participants: int.tryParse('${json['participants'] ?? 1}') ?? 1,
      trustedContactId: json['trustedContactId']?.toString(),
    );
  }
}
