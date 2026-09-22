import 'package:flutter/material.dart';

/// Stable brand tokens for España Outdoor.
///
/// Keep product state colors separate from the brand palette: warning,
/// danger and emergency must remain semantically unambiguous.
abstract final class OutdoorBrand {
  static const forest = Color(0xFF145A43);
  static const forestLight = Color(0xFF43B982);
  static const earth = Color(0xFFB38A55);
  static const earthLight = Color(0xFFE5C18A);
  static const sun = Color(0xFFF2A11A);
  static const water = Color(0xFF2E86A8);
  static const waterLight = Color(0xFF8EC9E5);
  static const rock = Color(0xFF687280);

  static const lightBackground = Color(0xFFF5F7F4);
  static const darkBackground = Color(0xFF0A1713);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF12211C);

  static const textLight = Color(0xFF10231E);
  static const textDark = Color(0xFFE8F0ED);
  static const textMutedLight = Color(0xFF4E625B);
  static const textMutedDark = Color(0xFFB8C8C2);

  static const success = Color(0xFF137A4B);
  static const info = Color(0xFF176B87);
  static const caution = Color(0xFFF2A11A);
  static const danger = Color(0xFFB42318);
  static const emergency = Color(0xFFC62828);
}

/// The primary España Outdoor mark: a compact relief/path symbol with a
/// restrained solar accent. It is intentionally text-free for small sizes.
class OutdoorBrandMark extends StatelessWidget {
  const OutdoorBrandMark({super.key, this.size = 48, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'España Outdoor',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _OutdoorBrandMarkPainter(dark: dark),
      ),
    );
  }
}

class _OutdoorBrandMarkPainter extends CustomPainter {
  const _OutdoorBrandMarkPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.scale(scale, scale);

    final mountain = Paint()
      ..color = dark ? OutdoorBrand.forestLight : OutdoorBrand.forest
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(12, 80)
      ..lineTo(43, 19)
      ..quadraticBezierTo(49, 10, 56, 19)
      ..lineTo(88, 80)
      ..quadraticBezierTo(90, 85, 83, 85)
      ..lineTo(17, 85)
      ..quadraticBezierTo(9, 85, 12, 80)
      ..close();
    canvas.drawPath(path, mountain);

    final route = Paint()
      ..color = dark ? OutdoorBrand.darkBackground : OutdoorBrand.lightSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final routePath = Path()
      ..moveTo(25, 67)
      ..cubicTo(34, 57, 40, 55, 48, 58)
      ..cubicTo(56, 61, 57, 70, 66, 71)
      ..cubicTo(72, 72, 76, 68, 80, 63);
    canvas.drawPath(routePath, route);

    final sun = Paint()
      ..color = OutdoorBrand.sun
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(78, 18), 9, sun);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OutdoorBrandMarkPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
