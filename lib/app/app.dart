import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/explore/explore_page.dart';
import '../features/home/home_page.dart';
import '../features/map/map_page.dart';
import '../features/offline/offline_page.dart';
import '../features/profile/profile_page.dart';
import '../features/pets/pets_page.dart';
import '../features/wildlife/wildlife_page.dart';
import '../features/weather/weather_page.dart';
import '../features/routes/route_detail_page.dart';
import '../../core/gpx/gpx_import_service.dart';
import '../../core/models/route_summary.dart';
import '../features/routes/routes_page.dart';
import '../features/safety/safety_page.dart';
import '../features/safety/route_plan_page.dart';
import '../features/safety/alerts_page.dart';
import '../features/safety/trusted_contacts_page.dart';
import 'theme.dart';

class EspanaOutdoorApp extends StatelessWidget {
  const EspanaOutdoorApp({super.key});

  static final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/explore', builder: (_, __) => const ExplorePage()),
      GoRoute(path: '/routes', builder: (_, __) => const RoutesPage()),
      GoRoute(
        path: '/routes/detail',
        builder: (_, state) {
          final extra = state.extra;
          return RouteDetailPage(
            route: extra is RouteSummary ? extra : null,
            track: extra is ImportedTrack ? extra : null,
          );
        },
      ),
      GoRoute(path: '/map', builder: (_, __) => const MapPage()),
      GoRoute(path: '/pets', builder: (_, __) => const PetsPage()),
      GoRoute(path: '/wildlife', builder: (_, __) => const WildlifePage()),
      GoRoute(path: '/weather', builder: (_, __) => const WeatherPage()),
      GoRoute(path: '/safety', builder: (_, __) => const SafetyPage()),
      GoRoute(path: '/safety/alerts', builder: (_, __) => const AlertsPage()),
      GoRoute(
        path: '/safety/plan',
        builder: (_, state) => RoutePlanPage(
          route: state.extra is RouteSummary ? state.extra as RouteSummary : null,
        ),
      ),
      GoRoute(
        path: '/safety/contacts',
        builder: (_, __) => const TrustedContactsPage(),
      ),
      GoRoute(path: '/offline', builder: (_, __) => const OfflinePage()),
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
