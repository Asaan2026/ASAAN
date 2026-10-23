import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vortex_app/core/localization/locale_controller.dart';
import 'package:vortex_app/core/theme/app_theme.dart';
import 'package:vortex_app/routes/app_router.dart';
import 'package:vortex_app/data/services/api_sync_service.dart';
import 'package:vortex_app/l10n/app_localizations.dart';

class CartxisApp extends StatefulWidget {
  const CartxisApp({super.key});

  @override
  State<CartxisApp> createState() => _CartxisAppState();
}

class _CartxisAppState extends State<CartxisApp> with WidgetsBindingObserver {
  final ApiSyncService _apiSyncService = ApiSyncService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocaleController.instance.load();
    _sendHeartbeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sendHeartbeat();
    }
  }

  Future<void> _sendHeartbeat() async {
    try {
      await _apiSyncService.sendHeartbeat();
    } catch (_) {
      // Ignore heartbeat errors to avoid blocking the app
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,

          // Theme
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.system, // TODO: Make this configurable via settings

          // Localization — the chosen language, or the phone's own if none.
          locale: LocaleController.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // Routing
          navigatorKey: AppRouter.navigatorKey,
          initialRoute: AppRouter.splash,
          onGenerateRoute: AppRouter.generateRoute,
          navigatorObservers: [AppRouter.routeObserver],

          // Builder for global configurations
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
