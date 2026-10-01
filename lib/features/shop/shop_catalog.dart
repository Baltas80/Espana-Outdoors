class ShopCategory {
  const ShopCategory({
    required this.name,
    required this.description,
    required this.icon,
  });

  final String name;
  final String description;
  final String icon;
}

class ShopProduct {
  const ShopProduct({
    required this.name,
    required this.category,
    required this.description,
    this.priceLabel,
    this.externalUrl,
  });

  final String name;
  final String category;
  final String description;
  final String? priceLabel;
  final String? externalUrl;
}

const shopCategories = <ShopCategory>[
  ShopCategory(
    name: 'Mochilas',
    description: 'Carga, hidratación y transporte para tus rutas.',
    icon: 'backpack',
  ),
  ShopCategory(
    name: 'Calzado',
    description: 'Calzado para senderismo, trekking y montaña.',
    icon: 'hiking',
  ),
  ShopCategory(
    name: 'Trekking',
    description: 'Equipamiento esencial para rutas y montaña.',
    icon: 'terrain',
  ),
  ShopCategory(
    name: 'Camping',
    description: 'Refugio, descanso, cocina e iluminación.',
    icon: 'camping',
  ),
  ShopCategory(
    name: 'Navegación',
    description: 'GPS, orientación y accesorios de navegación.',
    icon: 'navigation',
  ),
  ShopCategory(
    name: 'Seguridad',
    description: 'Preparación y material para situaciones imprevistas.',
    icon: 'health_and_safety',
  ),
  ShopCategory(
    name: 'Accesorios',
    description: 'Pequeño material que marca la diferencia en ruta.',
    icon: 'category',
  ),
];

/// Product data is deliberately empty until a verified supplier/affiliate
/// source is configured. No retailer, price or commission is invented here.
const shopProducts = <ShopProduct>[];
