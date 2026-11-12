import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'firebase_options.dart';
import 'src/auth_wrapper.dart';
import 'src/splash_screen.dart';
import 'src/theme/app_theme.dart';
import 'src/services/notification_service.dart';
import 'src/orders_screen.dart';

// Key global para navegar desde cualquier parte (notificaciones)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar transparent + light icons (dark theme)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF011713),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Crashlytics — captura errores automáticamente ──
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await NotificationService.init();

  // Navegar a Pedidos cuando el usuario toca una notificación
  OneSignal.Notifications.addClickListener((event) {
    final screen = event.notification.additionalData?['screen'] as String?;
    if (screen == 'orders') {
      navigatorKey.currentState?.push(
        AppTheme.pageRoute(const OrdersScreen()),
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urabá Market',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
