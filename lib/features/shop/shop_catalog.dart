class ShopCategory {
  const ShopCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.slug,
  });

  final String name;
  final String description;
  final String icon;
  final String slug;
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
  ShopCategory(name: 'Mochilas', slug: 'mochilas', description: 'Mochilas de senderismo, trekking, montaña y uso diario.', icon: 'backpack'),
  ShopCategory(name: 'Calzado', slug: 'calzado', description: 'Botas y zapatillas para senderismo, trekking y montaña.', icon: 'hiking'),
  ShopCategory(name: 'Ropa outdoor', slug: 'ropa-outdoor', description: 'Capas, impermeables, forros, pantalones y protección.', icon: 'checkroom'),
  ShopCategory(name: 'Trekking', slug: 'trekking', description: 'Equipamiento esencial para rutas y travesías.', icon: 'terrain'),
  ShopCategory(name: 'Camping', slug: 'camping', description: 'Tiendas, sacos, descanso, cocina e iluminación.', icon: 'camping'),
  ShopCategory(name: 'Hidratación', slug: 'hidratacion', description: 'Botellas, depósitos, filtros y sistemas de hidratación.', icon: 'water_drop'),
  ShopCategory(name: 'Navegación', slug: 'navegacion', description: 'GPS, brújulas, orientación y accesorios de navegación.', icon: 'navigation'),
  ShopCategory(name: 'Seguridad', slug: 'seguridad', description: 'Botiquines, señalización y material para emergencias.', icon: 'health_and_safety'),
  ShopCategory(name: 'Iluminación', slug: 'iluminacion', description: 'Frontales, linternas y soluciones de iluminación.', icon: 'light_mode'),
  ShopCategory(name: 'Accesorios', slug: 'accesorios', description: 'Pequeño material y complementos para tus salidas.', icon: 'category'),
];

/// Products stay empty until real Shopify/provider data is selected.
/// Never invent prices, suppliers, commissions or affiliate URLs.
const shopProducts = <ShopProduct>[];
