import 'package:flutter/material.dart';
import 'colors.dart';

abstract final class EOTextStyles {
  static const hero = TextStyle(color: EOColors.white, fontSize: 32, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const title = TextStyle(color: EOColors.white, fontSize: 20, height: 1.25, fontWeight: FontWeight.w700);
  static const cardTitle = TextStyle(color: EOColors.white, fontSize: 16, height: 1.3, fontWeight: FontWeight.w700);
  static const body = TextStyle(color: EOColors.white, fontSize: 14, height: 1.4, fontWeight: FontWeight.w400);
  static const secondary = TextStyle(color: EOColors.textSecondary, fontSize: 12, height: 1.35);
  static const label = TextStyle(color: EOColors.white, fontSize: 11, height: 1.2, fontWeight: FontWeight.w500);
}
