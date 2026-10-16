import 'package:flutter/material.dart';

import 'core/services/deep_link_parser.dart';
import 'core/services/deep_link_service.dart';
import 'core/theme.dart';
import 'features/details/screens/product_details_screen.dart';
import 'features/splash/screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Deep Linking service to listen for incoming deep links
  await DeepLinkService.instance.init(navigatorKey: appNavigatorKey);

  runApp(MyApp(navigatorKey: appNavigatorKey));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.navigatorKey,
  });

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey ?? appNavigatorKey,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final rawName = settings.name;
        if (rawName == null || rawName.isEmpty) return null;

        // Support route paths like /products/12 or /product/12 or /product/slug
        final uri = Uri.tryParse(rawName);
        if (uri != null) {
          final toParse = uri.hasScheme
              ? uri
              : Uri.parse('https://${DeepLinkService.webDomain}$rawName');

          final parsed = const ProductDeepLinkParser().parse(toParse);
          if (parsed != null) {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => ProductDetailsScreen(
                productId: parsed.productId,
                productSlug: parsed.productSlug,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
