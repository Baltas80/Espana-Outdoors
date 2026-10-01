/// Configuration for the future Shopify-backed España Outdoor storefront.
///
/// Values are supplied at build time so credentials are never hard-coded in
/// the repository. The storefront can remain empty until the Shopify catalog
/// is populated and the connection is configured.
class ShopConfig {
  const ShopConfig._();

  static const storeDomain = String.fromEnvironment('SHOPIFY_STORE_DOMAIN');
  static const storefrontToken =
      String.fromEnvironment('SHOPIFY_STOREFRONT_TOKEN');
  static const apiVersion = String.fromEnvironment(
    'SHOPIFY_API_VERSION',
    defaultValue: '2026-10',
  );

  static bool get isConfigured =>
      storeDomain.isNotEmpty && storefrontToken.isNotEmpty;

  static String get endpoint =>
      'https://$storeDomain/api/$apiVersion/graphql.json';
}
