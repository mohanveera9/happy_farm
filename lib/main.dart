import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_farm/models/user_provider.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/views/productdetails_screen.dart';
import 'package:happy_farm/presentation/main_screens/home_tab/services/product_service.dart';
import 'package:happy_farm/splash_screen.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'package:app_links/app_links.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks; // App Links instance
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      debugPrint("Error getting initial link: $e");
    }

    // Handle link stream (while app is running)
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri != null) {
          _handleIncomingLink(uri);
        }
      },
      onError: (err) => debugPrint("Error in uriLinkStream: $err"),
    );
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    if (uri.pathSegments.contains('product')) {
      final productId = uri.pathSegments.last;

      try {
        final productService = ProductService();
        final product = await productService.getProductById(productId);

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ProductDetails(product: product),
          ),
        );
      } catch (e) {
        debugPrint("Error fetching product for deep link: $e");
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Sabba Farm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
