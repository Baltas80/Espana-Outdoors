import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'outdoor_visuals.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/home.svg',
              size: 28,
            ),
            selectedIcon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/home.svg',
              size: 28,
            ),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/map.svg',
              size: 28,
            ),
            selectedIcon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/map.svg',
              size: 28,
            ),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/routes.svg',
              size: 28,
            ),
            selectedIcon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/routes.svg',
              size: 28,
            ),
            label: 'Rutas',
          ),
          NavigationDestination(
            icon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/safety.svg',
              size: 28,
            ),
            selectedIcon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/safety.svg',
              size: 28,
            ),
            label: 'Seguridad',
          ),
          NavigationDestination(
            icon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/profile.svg',
              size: 28,
            ),
            selectedIcon: OutdoorAssetIcon(
              asset: 'assets/visuals/icons/profile.svg',
              size: 28,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
