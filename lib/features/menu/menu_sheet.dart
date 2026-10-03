import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/eo_components.dart';

class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  static const _items = <({IconData icon, String label, String route})>[
    (icon: Icons.route_outlined, label: 'Mis rutas', route: '/routes'),
    (icon: Icons.download_outlined, label: 'Offline', route: '/offline'),
    (icon: Icons.cloud_outlined, label: 'Meteorología', route: '/weather/lightning'),
    (icon: Icons.explore_outlined, label: 'Instrumentos', route: '/instruments'),
    (icon: Icons.park_outlined, label: 'Naturaleza', route: '/natura'),
    (icon: Icons.pets_outlined, label: 'Fauna', route: '/wildlife'),
    (icon: Icons.person_outline, label: 'Ajustes', route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(EOSpacing.lg, EOSpacing.sm, EOSpacing.lg, EOSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: EOColors.textSecondary.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: EOSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Menú', style: EOTextStyles.title),
            ),
            const SizedBox(height: EOSpacing.sm),
            ..._items.map(
              (item) => ListTile(
                leading: Icon(item.icon, color: EOColors.green),
                title: Text(item.label, style: EOTextStyles.body),
                trailing: const Icon(Icons.chevron_right, color: EOColors.textSecondary),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(item.route);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
