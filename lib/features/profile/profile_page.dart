import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/photo_atlas.dart';
import '../../core/auth/oidc_config.dart';
import '../../infrastructure/auth/openidconnect_auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final OpenIdConnectAuthService _auth =
      OpenIdConnectAuthService(OidcConfig.fromEnvironment());
  bool? _signedIn;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshAuth();
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  Future<void> _refreshAuth() async {
    if (!_auth.config.isConfigured) {
      if (mounted) setState(() => _signedIn = false);
      return;
    }
    try {
      final value = await _auth.isSignedIn();
      if (mounted) setState(() => _signedIn = value);
    } on Object {
      if (mounted) setState(() => _signedIn = false);
    }
  }

  Future<void> _signIn() async {
    if (!_auth.config.isConfigured) {
      _show('Identidad OIDC no configurada para este entorno.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _auth.signIn(context);
      await _refreshAuth();
    } on Object catch (error) {
      if (mounted) _show('No se pudo iniciar sesión: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await _auth.signOut();
      await _refreshAuth();
    } on Object catch (error) {
      if (mounted) _show('No se pudo cerrar sesión: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

  @override
  Widget build(BuildContext context) {
    final signedIn = _signedIn == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const ClipOval(
                        child: OutdoorPhotoTile(
                          index: 0,
                          width: 78,
                          height: 78,
                          borderRadius: 0,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              signedIn ? 'Aventurero' : 'Aventurero',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 3),
                            const Text('Usuario'),
                            const SizedBox(height: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Explorador',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: signedIn ? 'Cerrar sesión' : 'Iniciar sesión',
                        onPressed: _busy ? null : (signedIn ? _signOut : _signIn),
                        icon: Icon(signedIn ? Icons.logout : Icons.login),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: _Stat(value: '24', label: 'Rutas')),
                      Expanded(child: _Stat(value: '6', label: 'Parques')),
                      Expanded(child: _Stat(value: '12', label: 'Favoritos')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ProfileItem(
            icon: Icons.favorite_border,
            title: 'Rutas guardadas',
            onTap: () => context.go('/routes'),
          ),
          _ProfileItem(
            icon: Icons.download_for_offline_outlined,
            title: 'Mapas offline',
            onTap: () => context.go('/offline'),
          ),
          _ProfileItem(
            icon: Icons.photo_library_outlined,
            title: 'Mis fotos',
          ),
          _ProfileItem(
            icon: Icons.place_outlined,
            title: 'Puntos de interés',
            onTap: () => context.go('/explore'),
          ),
          _ProfileItem(
            icon: Icons.history,
            title: 'Historial',
          ),
          _ProfileItem(
            icon: Icons.emoji_events_outlined,
            title: 'Logros',
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              onTap: () => context.go('/plans'),
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text(
                'Free · Premium · Professional',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Capacidades y funciones del servicio.'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
