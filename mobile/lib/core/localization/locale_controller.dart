import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the language the person chose, and hands it to the app.
///
/// Lives above the router so every screen — including sign-in and registration
/// — is translated, not just the ones inside the main shell. `null` means
/// "follow the phone's own language".
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const String _prefsKey = 'app_locale';

  String? _code;
  bool _loaded = false;

  /// The chosen language code, or null to follow the system.
  String? get code => _code;

  bool get isLoaded => _loaded;

  Locale? get locale => _code == null ? null : Locale(_code!);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null && saved.isNotEmpty) {
        _code = saved;
      }
    } catch (_) {
      // A missing preference just means we follow the system language.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocale(String? code) async {
    _code = (code == null || code.isEmpty) ? null : code;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_code == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, _code!);
      }
    } catch (_) {
      // If the preference cannot be saved we still switch for this session.
    }

    notifyListeners();
  }
}
