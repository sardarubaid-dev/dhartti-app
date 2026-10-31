import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dhartti/IntroScreens/splash_screen.dart';
import 'package:dhartti/service/firebase_notification_service.dart';
import 'package:dhartti/service/deep_link_service.dart';
import 'package:dhartti/UserScreen/PropertyScreen/PropertyDetailPage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean up any legacy background service handles from previously installed apps
  try {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((k) => k.toLowerCase().contains('deliveazone') || k.toLowerCase().contains('location_provider')).toList();
    for (final k in keysToRemove) {
      await prefs.remove(k);
    }
  } catch (_) {}
  
  // 1. Instantly launch App UI so Splash Screen renders immediately without white freeze
  runApp(const MyApp());

  // 2. Initialize background services asynchronously
  Future.microtask(() async {
    try {
      DeepLinkService.instance.initialize(navigatorKey);
      await FirebaseNotificationService.instance.initialize(navKey: navigatorKey);
    } catch (e) {
      debugPrint("Service init error: $e");
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Dhartti',
      theme: ThemeData(
        primaryColor: const Color(0xFF059669),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final uri = Uri.tryParse(settings.name ?? '');
        if (uri != null) {
          final segments = uri.pathSegments;
          if (segments.contains('room-detail')) {
            final idx = segments.indexOf('room-detail');
            if (idx + 1 < segments.length) {
              final propId = int.tryParse(segments[idx + 1]);
              if (propId != null) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => PropertyDetailPage(propertyId: propId),
                );
              }
            }
          }
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      },
    );
  }
}
