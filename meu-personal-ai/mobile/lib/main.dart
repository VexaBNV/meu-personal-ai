import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/payments/data/revenue_cat_service.dart';

// FCM background handler (deve ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientação
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Hive
  await Hive.initFlutter();
  await Hive.openBox('workout_cache');
  await Hive.openBox('user_cache');

  // RevenueCat — inicializar ANTES de runApp
  await _initRevenueCat();

  // Status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: MeuPersonalAiApp()));
}

Future<void> _initRevenueCat() async {
  // API keys em dart-define:
  // flutter run --dart-define=REVENUECAT_API_KEY_IOS=appl_xxx
  //              --dart-define=REVENUECAT_API_KEY_ANDROID=goog_xxx
  const iosKey     = String.fromEnvironment('REVENUECAT_API_KEY_IOS');
  const androidKey = String.fromEnvironment('REVENUECAT_API_KEY_ANDROID');

  if (iosKey.isEmpty && androidKey.isEmpty) {
    // Em desenvolvimento sem chaves configuradas — skip silencioso
    debugPrint('RevenueCat: keys not configured, skipping init');
    return;
  }

  await Purchases.setLogLevel(LogLevel.debug);
  final config = Platform.isIOS
      ? PurchasesConfiguration(iosKey)
      : PurchasesConfiguration(androidKey);
  await Purchases.configure(config);
}

class MeuPersonalAiApp extends ConsumerWidget {
  const MeuPersonalAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode  = ref.watch(themeProvider);
    final router     = ref.watch(routerProvider);

    return MaterialApp.router(
      title:           AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode:       themeMode,
      theme:           AppTheme.light(),
      darkTheme:       AppTheme.dark(),
      routerConfig:    router,
    );
  }
}
