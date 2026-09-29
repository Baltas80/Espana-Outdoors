import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MapNavigationSmokePage extends StatefulWidget {
  const MapNavigationSmokePage({super.key});

  @override
  State<MapNavigationSmokePage> createState() => _MapNavigationSmokePageState();
}

class _MapNavigationSmokePageState extends State<MapNavigationSmokePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        context.go('/map');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
