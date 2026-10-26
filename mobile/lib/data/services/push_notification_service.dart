import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/notification_navigator.dart';
import 'notification_service.dart';

/// Push notifications for the phone itself.
///
/// Two jobs: ask the phone for its Firebase push token and hand that token to
/// our server (so an order update can reach the phone as a real notification),
/// and take the token back when the person signs out so the next person on the
/// phone does not receive the last person's messages.
///
/// If Firebase is not set up, every method quietly does nothing. The in-app
/// notification centre keeps working on its own, so nothing breaks.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final NotificationService _notifications = NotificationService();

  static const String _tokenKey = 'fcm_token';

  bool _initialized = false;

  /// Start Firebase and keep the phone's push token in step with the server.
  /// Safe to call on every app start.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;

      // Android 13+ and iOS show a permission prompt here. A "no" is respected
      // and only means no push; it never breaks the app.
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // On iOS, show the banner while the app is open instead of swallowing it.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // A token can change: a reinstall, a restore, or cleared app data. Keep
      // the server pointing at the phone's current token.
      messaging.onTokenRefresh.listen(_saveAndRegister);

      // Tapping a push must open the right screen. onMessageOpenedApp covers
      // the app being in the background; getInitialMessage covers a tap that
      // launched the app from cold. Without these the tap only opened the app
      // and left the customer on the home screen.
      FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _openFromMessage(initialMessage);
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveAndRegister(token);
      }

      _initialized = true;
    } catch (e, stack) {
      // Firebase is optional. Without it the app runs and the in-app
      // notification centre still works.
      // Log error so it is not silently swallowed.
      // Note: In production we still continue; this helps debug.
      try {
        // Avoid using print in favor of logging if available
        // But keep it simple - the app should not crash
        print('PushNotificationService initialize failed: $e');
      } catch (_) {}
    }
  }

  /// Route a tapped push to the screen its payload points at.
  void _openFromMessage(RemoteMessage message) {
    NotificationNavigator.handle(
      message.data,
      type: message.data['type'] as String?,
      openFallback: true,
    );
  }

  /// Send the current token to the server, if someone is signed in.
  ///
  /// Called after login and on app start so the phone is always registered.
  Future<void> registerForCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Register whenever an auth token exists, not only when an explicit
      // isLoggedIn flag is set — the flag can be missing on some code paths
      // (e.g. a restored session), which previously made the device token
      // never reach the server and produced "No phone is signed in".
      final authToken = prefs.getString('auth_token');
      if (authToken == null || authToken.isEmpty) return;

      final token = await _currentToken();
      if (token == null || token.isEmpty) return;

      await _notifications.registerDevice(
        token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (e) {
      // Best-effort: a failure here must never disturb sign-in, but log it
      // so a silent failure is at least visible.
      try {
        print('PushNotificationService registerForCurrentUser failed: $e');
      } catch (_) {}
    }
  }

  /// Forget this phone, for sign-out, so the next person on it is not pushed
  /// the previous person's order updates.
  Future<void> removeDevice() async {
    try {
      final token = await _currentToken();
      if (token == null || token.isEmpty) return;

      // Cap the wait: signing out must not hang if the network is slow.
      await _notifications
          .unregisterDevice(token)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // If it did not go through, the row is simply replaced on the next login.
      try {
        print('PushNotificationService removeDevice failed: $e');
      } catch (_) {}
    }
  }

  Future<void> _saveAndRegister(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await registerForCurrentUser();
  }

  Future<String?> _currentToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved != null && saved.isNotEmpty) return saved;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_tokenKey, token);
      }
      return token;
    } catch (e) {
      try {
        print('PushNotificationService _currentToken failed: $e');
      } catch (_) {}
      return null;
    }
  }
}
