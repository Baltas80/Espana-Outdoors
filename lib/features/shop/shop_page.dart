import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import 'shop_catalog.dart';
import 'shop_config.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              pinned: true,
              title: Row(children: [
                OutdoorBrandMark(size: 42, dark: dark),
                const SizedBox(width: 10),
                const Text('TIENDA'),
              ]),
              actions: [
                IconButton(
                  tooltip: 'Volver al inicio',
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _HeroCard(theme: theme),
                  const SizedBox(height: 24),
                  Text('Equípate para salir preparado', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Explora el equipamiento por actividad. El catálogo se conectará a Shopify cuando incorporemos los primeros productos reales.', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 18),
                  _CategoryGrid(categories: shopCategories),
                  const SizedBox(height: 26),
                  _CatalogStatus(products: shopProducts),
                  const SizedBox(height: 26),
                  _ShopBackendStatus(configured: ShopConfig.isConfigured),
                  const SizedBox(height: 26),
                  const _CommercialPrinciples(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.surfaceContainerHighest],
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.storefront_outlined, size: 48, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('España Outdoor Shop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Equipamiento para senderismo, trekking, montaña, camping y seguridad outdoor.'),
          SizedBox(height: 14),
          Text('Selección de material. Sin inventario propio en la fase inicial.'),
        ])),
      ]),
    ),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});
  final List<ShopCategory> categories;

  IconData _icon(String name) {
    switch (name) {
      case 'backpack': return Icons.backpack_outlined;
      case 'hiking': return Icons.hiking;
      case 'terrain': return Icons.terrain;
      case 'camping': return Icons.cabin_outlined;
      case 'navigation': return Icons.navigation_outlined;
      case 'health_and_safety': return Icons.health_and_safety_outlined;
      case 'checkroom': return Icons.checkroom_outlined;
      case 'water_drop': return Icons.water_drop_outlined;
      case 'light_mode': return Icons.light_mode_outlined;
      default: return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900 ? 4 : width >= 600 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: columns >= 4 ? 1.25 : 1.12,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showCategoryInfo(context, category),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_icon(category.icon), size: 32),
                const SizedBox(height: 10),
                Text(category.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(category.description, maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryInfo(BuildContext context, ShopCategory category) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(category.description),
          const SizedBox(height: 16),
          const Text('Esta categoría ya está definida. Los productos reales se incorporarán después y se cargarán desde Shopify o proveedores verificados.'),
        ]),
      ),
    );
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({required this.products});
  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isNotEmpty) return const SizedBox.shrink();
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.inventory_2_outlined),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Catálogo comercial en preparación', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('La tienda está estructurada y lista para recibir productos reales. No mostramos marcas, precios ni enlaces inventados.', style: Theme.of(context).textTheme.bodyMedium),
      ])),
    ])));
  }
}

class _ShopBackendStatus extends StatelessWidget {
  const _ShopBackendStatus({required this.configured});
  final bool configured;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: Icon(configured ? Icons.cloud_done_outlined : Icons.cloud_queue_outlined),
    title: const Text('Infraestructura de comercio', style: TextStyle(fontWeight: FontWeight.w900)),
    subtitle: Text(configured ? 'Shopify está configurado para el catálogo.' : 'Shopify queda preparado para conectar el catálogo cuando tengamos el dominio de tienda y el token Storefront.'),
  ));
}

class _CommercialPrinciples extends StatelessWidget {
  const _CommercialPrinciples();
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
    Text('Modelo de la tienda', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
    SizedBox(height: 12),
    _Principle(icon: Icons.storefront_outlined, text: 'Shopify como plataforma comercial cuando configuremos el catálogo.'),
    _Principle(icon: Icons.inventory_2_outlined, text: 'Sin inventario propio hasta validar qué productos tienen demanda.'),
    _Principle(icon: Icons.analytics_outlined, text: 'Medición de clics, productos y categorías para decidir dónde invertir.'),
    _Principle(icon: Icons.handshake_outlined, text: 'Preparada para evolucionar de afiliación a acuerdos directos con marcas.'),
  ])));
}

class _Principle extends StatelessWidget {
  const _Principle({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 22),
    const SizedBox(width: 10),
    Expanded(child: Text(text)),
  ]));
}
