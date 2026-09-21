import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';
import '../features/map/map_page.dart';
import '../features/safety/safety_page.dart';
import '../features/profile/profile_page.dart';
import 'theme.dart';

class EspanaOutdoorApp extends StatelessWidget {
  const EspanaOutdoorApp({super.key});

  static final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/map', builder: (_, __) => const MapPage()),
      GoRoute(path: '/safety', builder: (_, __) => const SafetyPage()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'España Outdoor',
      debugShowCheckedModeBanner: false,
      theme: buildOutdoorTheme(Brightness.light),
      darkTheme: buildOutdoorTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
