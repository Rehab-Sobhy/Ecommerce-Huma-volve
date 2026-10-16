import 'package:equatable/equatable.dart';

/// Parsed data for a product deep link.
class ProductDeepLinkData extends Equatable {
  const ProductDeepLinkData({
    this.productId,
    this.productSlug,
    required this.uri,
  });

  /// The product ID extracted from the deep link, if present.
  final int? productId;

  /// The product slug extracted from the deep link, if present.
  final String? productSlug;

  /// The original deep link URI.
  final Uri uri;

  /// Whether this deep link contains enough information to identify a product.
  bool get isValid =>
      (productId != null && productId! > 0) ||
      (productSlug != null && productSlug!.trim().isNotEmpty);

  @override
  List<Object?> get props => [productId, productSlug, uri];
}

/// Parser for product deep links across custom schemes and web URLs.
///
/// Supported schemes:
/// - Custom: `humavolve://product/{id}`, `humavolve://products/{id}`, `ecommerce://...`
/// - Web: `https://ecommerce.humavolve.com/products/{id}`, `http://...`
/// - Query parameters: `?id=12`, `?productId=12`, `?slug=shoes`
class ProductDeepLinkParser {
  const ProductDeepLinkParser();

  /// Supported URL schemes
  static const Set<String> supportedSchemes = {
    'humavolve',
    'ecommerce',
    'http',
    'https',
  };

  /// Supported web hosts for App Links
  static const Set<String> supportedHosts = {
    'ecommerce.humavolve.com',
    'humavolve.com',
    'app.humavolve.com',
  };

  /// Parses a given [uri] into a [ProductDeepLinkData], or returns `null`
  /// if the URI does not represent a product deep link.
  ProductDeepLinkData? parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (!supportedSchemes.contains(scheme)) {
      return null;
    }

    int? productId;
    String? productSlug;

    // Check query parameters first (e.g. ?id=12 or ?productId=12 or ?slug=classic)
    final queryId = uri.queryParameters['id'] ?? uri.queryParameters['productId'];
    if (queryId != null) {
      productId = int.tryParse(queryId);
    }
    final querySlug = uri.queryParameters['slug'];
    if (querySlug != null && querySlug.trim().isNotEmpty) {
      productSlug = querySlug.trim();
    }

    final host = uri.host.toLowerCase();
    final pathSegments = uri.pathSegments
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (scheme == 'http' || scheme == 'https') {
      // Must be a supported host (or empty host in relative URIs)
      if (host.isNotEmpty && !supportedHosts.contains(host)) {
        return null;
      }

      // Check path segments: /products/{id_or_slug} or /product/{id_or_slug}
      if (pathSegments.isNotEmpty) {
        final firstSegment = pathSegments[0].toLowerCase();
        if (firstSegment == 'product' || firstSegment == 'products') {
          if (pathSegments.length > 1) {
            final target = pathSegments[1];
            final parsedId = int.tryParse(target);
            if (parsedId != null) {
              productId ??= parsedId;
            } else if (target.trim().isNotEmpty) {
              productSlug ??= target.trim();
            }
          }
        }
      }
    } else {
      // Custom scheme: humavolve:// or ecommerce://
      // Patterns:
      // 1. humavolve://product/12  (host='product', pathSegments=['12'])
      // 2. humavolve://products/12 (host='products', pathSegments=['12'])
      // 3. humavolve:///product/12 (host='', pathSegments=['product', '12'])
      // 4. humavolve://product?id=12 (host='product', pathSegments=[])
      if (host == 'product' || host == 'products') {
        if (pathSegments.isNotEmpty) {
          final target = pathSegments[0];
          final parsedId = int.tryParse(target);
          if (parsedId != null) {
            productId ??= parsedId;
          } else if (target.trim().isNotEmpty) {
            productSlug ??= target.trim();
          }
        }
      } else if (pathSegments.isNotEmpty) {
        final firstSegment = pathSegments[0].toLowerCase();
        if (firstSegment == 'product' || firstSegment == 'products') {
          if (pathSegments.length > 1) {
            final target = pathSegments[1];
            final parsedId = int.tryParse(target);
            if (parsedId != null) {
              productId ??= parsedId;
            } else if (target.trim().isNotEmpty) {
              productSlug ??= target.trim();
            }
          }
        }
      }
    }

    final result = ProductDeepLinkData(
      productId: productId,
      productSlug: productSlug,
      uri: uri,
    );

    return result.isValid ? result : null;
  }
}
