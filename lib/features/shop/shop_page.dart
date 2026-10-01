import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand.dart';
import 'shop_catalog.dart';

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
              title: Row(
                children: [
                  OutdoorBrandMark(size: 42, dark: dark),
                  const SizedBox(width: 10),
                  const Text('TIENDA'),
                ],
              ),
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
                  Text(
                    'Equípate para salir preparado',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selección de equipamiento outdoor organizada por actividad. '
                    'La primera fase funcionará mediante enlaces a proveedores y programas de afiliación verificados.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 18),
                  _CategoryGrid(categories: shopCategories),
                  const SizedBox(height: 26),
                  _CatalogStatus(products: shopProducts),
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
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'España Outdoor Shop',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Material seleccionado para rutas, montaña, camping y seguridad outdoor.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<ShopCategory> categories;

  IconData _icon(String name) {
    switch (name) {
      case 'backpack':
        return Icons.backpack_outlined;
      case 'hiking':
        return Icons.hiking;
      case 'terrain':
        return Icons.terrain;
      case 'camping':
        return Icons.cabin_outlined;
      case 'navigation':
        return Icons.navigation_outlined;
      case 'health_and_safety':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showCategoryInfo(context, category),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icon(category.icon), size: 34),
                  const SizedBox(height: 10),
                  Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(category.description),
            const SizedBox(height: 16),
            const Text(
              'Catálogo en preparación. Los productos se incorporarán únicamente cuando exista un proveedor y un enlace comercial verificado.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({required this.products});

  final List<ShopProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catálogo comercial en preparación',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'La estructura ya está preparada para incorporar productos reales. No se muestran marcas, precios ni enlaces inventados.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommercialPrinciples extends StatelessWidget {
  const _CommercialPrinciples();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modelo de la tienda',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _Principle(
              icon: Icons.link_outlined,
              text: 'Primera fase: afiliación y enlaces a proveedores verificados.',
            ),
            _Principle(
              icon: Icons.warehouse_outlined,
              text: 'Sin inventario propio ni costes de almacenamiento en el lanzamiento.',
            ),
            _Principle(
              icon: Icons.analytics_outlined,
              text: 'Preparada para medir clics y detectar categorías con demanda real.',
            ),
            _Principle(
              icon: Icons.storefront_outlined,
              text: 'Futura evolución hacia acuerdos directos con marcas y proveedores.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
