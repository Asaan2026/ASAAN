import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vortex_app/app.dart';
import 'package:vortex_app/core/utils/app_version.dart';
import 'package:vortex_app/core/utils/currency_utils.dart';
import 'package:vortex_app/core/config/api_config.dart';
import 'package:vortex_app/data/services/push_notification_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Allow self-signed certificates in development mode
  if (!ApiConfig.isProduction) {
    HttpOverrides.global = _DevHttpOverrides();
  }

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // The real installed version, for the screens that show it.
  await AppVersion.load();

  // Preload default currency
  CurrencyUtils.preload();

  // Start push in the background. It asks the phone for a push token and hands
  // it to the server when someone is signed in. Not awaited so the first screen
  // still appears immediately.
  PushNotificationService.instance.initialize();

  // Run the app
  runApp(const CartxisApp());
}

/// HTTP Overrides for development to accept self-signed certificates
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
