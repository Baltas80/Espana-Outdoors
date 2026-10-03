import 'package:flutter/material.dart';

abstract final class EOShadows {
  static const card = <BoxShadow>[
    BoxShadow(blurRadius: 18, spreadRadius: 0, offset: Offset(0, 8), color: Color(0x33000000)),
  ];
  static const floating = <BoxShadow>[
    BoxShadow(blurRadius: 24, spreadRadius: 0, offset: Offset(0, 10), color: Color(0x44000000)),
  ];
}
