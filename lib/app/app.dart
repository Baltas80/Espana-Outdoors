import 'package:flutter/material.dart';

import '../core/contracts/routing_service.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/alerts_page.dart';
import '../features/explore/explore_page.dart';
import '../features/home/home_page.dart';
import '../features/map/map_page.dart';
import '../features/navigation/navigation_page.dart';
import '../features/offline/offline_page.dart';
import '../features/profile/plans_page.dart';
import '../features/profile/profile_page.dart';
import '../features/pets/pets_page.dart';
import '../features/rescue/rescue_link_page.dart';
import '../features/wildlife/wildlife_page.dart';
import '../features/natura/natura_protect_page.dart';
import '../features/routes/route_detail_page.dart';
import '../features/routes/route_planner_page.dart';
import '../../core/gpx/gpx_import_service.dart';
import '../../core/models/route_summary.dart';
import '../features/routes/routes_page.dart';
import '../features/safety/safety_page.dart';
import '../features/safety/trusted_contacts_page.dart';
import 'theme.dart';

class EspanaOutdoorApp extends StatelessWidget {
  const EspanaOutdoorApp({super.key});

  static Widget _withBackNavigation(Widget child, {String fallback = '/'}) {
    return _BackNavigationScope(fallback: fallback, child: child);
  }

  static final _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/explore', builder: (_, __) => _withBackNavigation(const ExplorePage())),
      GoRoute(path: '/routes', builder: (_, __) => _withBackNavigation(const RoutesPage())),
      GoRoute(path: '/routes/planner', builder: (_, __) => _withBackNavigation(const RoutePlannerPage(), fallback: '/routes')),
      GoRoute(
        path: '/routes/detail',
        builder: (_, state) {
          final extra = state.extra;
          return _withBackNavigation(
            RouteDetailPage(
              route: extra is RouteSummary ? extra : null,
              track: extra is ImportedTrack ? extra : null,
            ),
            fallback: '/routes',
          );
        },
      ),
      GoRoute(path: '/map', builder: (_, __) => _withBackNavigation(const MapPage())),
      GoRoute(path: '/navigation', builder: (_, state) {
        final route = state.extra is RouteResult ? state.extra as RouteResult : null;
        return _withBackNavigation(NavigationPage(route: route), fallback: '/routes');
      }),
      GoRoute(path: '/pets', builder: (_, __) => _withBackNavigation(const PetsPage())),
      GoRoute(path: '/wildlife', builder: (_, __) => _withBackNavigation(const WildlifePage())),
      GoRoute(path: '/natura', builder: (_, __) => _withBackNavigation(const NaturaProtectPage())),
      GoRoute(path: '/alerts', builder: (_, __) => _withBackNavigation(const AlertsPage())),
      GoRoute(path: '/rescue', builder: (_, __) => _withBackNavigation(const RescueLinkPage())),
      GoRoute(path: '/safety', builder: (_, __) => _withBackNavigation(const SafetyPage())),
      GoRoute(
        path: '/safety/contacts',
        builder: (_, __) => _withBackNavigation(const TrustedContactsPage(), fallback: '/safety'),
      ),
      GoRoute(path: '/offline', builder: (_, __) => _withBackNavigation(const OfflinePage())),
      GoRoute(path: '/profile', builder: (_, __) => _withBackNavigation(const ProfilePage())),
      GoRoute(path: '/plans', builder: (_, __) => _withBackNavigation(const PlansPage(), fallback: '/profile')),
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

/// Keeps Android/iOS back navigation inside the app when a top-level page was
/// reached with go() and therefore has no Navigator history to pop.
///
/// If a real route stack exists, the normal pop is preserved. Otherwise the
/// user is returned to the logical parent/home destination instead of closing
/// the application. The home route itself remains the normal app root.
class _BackNavigationScope extends StatelessWidget {
  const _BackNavigationScope({required this.child, required this.fallback});

  final Widget child;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !canPop) {
          context.go(fallback);
        }
      },
      child: child,
    );
  }
}
