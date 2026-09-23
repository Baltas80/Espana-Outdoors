import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(signedIn ? 'Cuenta conectada' : 'Aventura'),
              subtitle: Text(
                signedIn
                    ? 'Identidad protegida mediante OpenID Connect.'
                    : 'Perfil local · identidad opcional',
              ),
              trailing: IconButton(
                tooltip: signedIn ? 'Cerrar sesión' : 'Iniciar sesión',
                onPressed: _busy ? null : (signedIn ? _signOut : _signIn),
                icon: Icon(signedIn ? Icons.logout : Icons.login),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: () => context.go('/plans'),
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Free · Premium · Professional', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Consulta las capacidades de cada plan.'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 16),
          const _Section(title: 'Privacidad', items: [
            _Item(icon: Icons.location_on_outlined, title: 'Permisos de ubicación', subtitle: 'Controla cuándo puede acceder la app.'),
            _Item(icon: Icons.lock_outline, title: 'Datos y seguridad', subtitle: 'Minimización, almacenamiento y eliminación.'),
            _Item(icon: Icons.download_outlined, title: 'Exportar mis datos', subtitle: 'Preparado para portabilidad.'),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Aventura', items: [
            _Item(icon: Icons.pets_outlined, title: 'Mis mascotas', subtitle: 'Preferencias para rutas y riesgos.', onTap: () => context.go('/pets')),
            _Item(icon: Icons.offline_bolt_outlined, title: 'Contenido offline', subtitle: 'Gestiona mapas y datos descargados.', onTap: () => context.go('/offline')),
            _Item(icon: Icons.eco_outlined, title: 'NATURA PROTECT', subtitle: 'Conservación y navegación responsable.', onTap: () => context.go('/natura')),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Card(child: Column(children: [for (var i = 0; i < items.length; i++) ...[items[i], if (i != items.length - 1) const Divider(height: 1, indent: 72)]])),
        ],
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      );
}
