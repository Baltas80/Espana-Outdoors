import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

class OfflineMbtilesLayer extends StatelessWidget {
  const OfflineMbtilesLayer({required this.anchor, super.key});

  final LatLng anchor;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
