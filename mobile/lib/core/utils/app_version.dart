import 'package:package_info_plus/package_info_plus.dart';

/// The version of the app that is actually installed.
///
/// This used to be a constant somebody had to remember to edit, and it drifted:
/// the shop published 2.8.1 while the About and Profile screens still said
/// 2.6.0, so nobody could tell which build a customer was running. It is now
/// read from the installed package itself, so it can never disagree with the
/// APK again.
class AppVersion {
  AppVersion._();

  static String _version = '';
  static String _build = '';

  /// Read once while the app starts. Safe to call more than once.
  static Future<void> load() async {
    if (_version.isNotEmpty) return;

    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
      _build = info.buildNumber;
    } catch (_) {
      // Leave it blank rather than showing a number that might be wrong.
    }
  }

  /// "2.8.1", or empty before [load] has finished.
  static String get value => _version;

  /// "2.8.1 (16)" for the About screen, where the build number helps when
  /// somebody reports a problem.
  static String get detailed {
    if (_version.isEmpty) return '';

    return _build.isEmpty ? _version : '$_version ($_build)';
  }
}
