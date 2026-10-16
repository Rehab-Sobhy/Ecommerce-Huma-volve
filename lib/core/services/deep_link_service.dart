import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../../features/details/screens/product_details_screen.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import 'deep_link_parser.dart';

/// Central service responsible for listening to, parsing, and dispatching
/// deep links targeting the Product Details feature.
class DeepLinkService {
  DeepLinkService({
    this.appLinks,
    ProductDeepLinkParser? parser,
    this.navigatorKey,
    this.repository,
  }) : _parser = parser ?? const ProductDeepLinkParser();

  static final DeepLinkService instance = DeepLinkService();

  final AppLinks? appLinks;
  final ProductDeepLinkParser _parser;
  GlobalKey<NavigatorState>? navigatorKey;
  ProductRepository? repository;

  StreamSubscription<Uri>? _linkSubscription;
  final StreamController<ProductDeepLinkData> _linkController =
      StreamController<ProductDeepLinkData>.broadcast();

  ProductDeepLinkData? _pendingLink;

  /// Stream of successfully parsed product deep links.
  Stream<ProductDeepLinkData> get onProductDeepLink => _linkController.stream;

  /// The currently pending deep link that hasn't been navigated yet.
  ProductDeepLinkData? get pendingLink => _pendingLink;

  /// Primary domain used for universal web links.
  static const String webDomain = 'ecommerce.humavolve.com';

  /// Primary custom scheme used for direct app links.
  static const String appScheme = 'humavolve';

  /// Attaches navigator and initializes deep link listeners.
  Future<void> init({
    GlobalKey<NavigatorState>? navigatorKey,
    ProductRepository? repository,
  }) async {
    if (navigatorKey != null) {
      this.navigatorKey = navigatorKey;
    }
    if (repository != null) {
      this.repository = repository;
    }

    final links = appLinks ?? AppLinks();

    // 1. Listen for incoming links while the app is running (foreground/background)
    _linkSubscription?.cancel();
    _linkSubscription = links.uriLinkStream.listen(
      (uri) {
        handleUri(uri);
      },
      onError: (err) {
        debugPrint('DeepLinkService error receiving link: $err');
      },
    );

    // 2. Check for initial link when app launched from terminated state
    try {
      final initialUri = await links.getInitialLink();
      if (initialUri != null) {
        handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService error reading initial link: $e');
    }
  }

  /// Sets or updates the navigator key (e.g. from MaterialApp).
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    if (_pendingLink != null) {
      consumePendingLink();
    }
  }

  /// Sets or updates the product repository used for fetching.
  void setRepository(ProductRepository repository) {
    this.repository = repository;
  }

  /// Processes a [Uri] and navigates to the Product Details feature if valid.
  bool handleUri(Uri uri) {
    final parsed = _parser.parse(uri);
    if (parsed == null) {
      return false;
    }

    _linkController.add(parsed);

    final navState = navigatorKey?.currentState;
    if (navState != null) {
      _navigateToProduct(navState, parsed);
      _pendingLink = null;
    } else {
      _pendingLink = parsed;
    }

    return true;
  }

  /// Navigates to any pending link stored when the navigator wasn't ready.
  bool consumePendingLink() {
    final data = _pendingLink;
    final navState = navigatorKey?.currentState;
    if (data != null && navState != null) {
      _pendingLink = null;
      _navigateToProduct(navState, data);
      return true;
    }
    return false;
  }

  void _navigateToProduct(
    NavigatorState navigator,
    ProductDeepLinkData data,
  ) {
    navigator.push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/products/${data.productId ?? data.productSlug}',
          arguments: data,
        ),
        builder: (context) => ProductDetailsScreen(
          productId: data.productId,
          productSlug: data.productSlug,
          repository: repository,
        ),
      ),
    );
  }

  /// Generates a universal web link (HTTPS) for sharing.
  /// Example: https://ecommerce.humavolve.com/products/42
  static String buildWebLink({required int productId}) {
    return 'https://$webDomain/products/$productId';
  }

  /// Generates a custom scheme deep link for sharing or direct invocation.
  /// Example: humavolve://products/42
  static String buildCustomSchemeLink({required int productId}) {
    return '$appScheme://products/$productId';
  }

  /// Generates a universal web link by slug.
  /// Example: https://ecommerce.humavolve.com/product/classic-sneakers
  static String buildWebSlugLink({required String slug}) {
    return 'https://$webDomain/product/$slug';
  }

  /// Generates a custom scheme deep link by slug.
  /// Example: humavolve://product/classic-sneakers
  static String buildCustomSchemeSlugLink({required String slug}) {
    return '$appScheme://product/$slug';
  }

  /// Disposes active subscriptions.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _linkController.close();
  }
}
