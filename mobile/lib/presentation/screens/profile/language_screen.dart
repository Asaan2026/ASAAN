import 'package:flutter/material.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../data/models/app_locale_model.dart';
import '../../../data/services/locale_service.dart';
import '../../../l10n/app_localizations.dart';

/// Lets the person pick the language for the whole app.
///
/// The choices come from the shop so a newly added language shows up on its
/// own. "System default" follows whatever the phone is set to.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final LocaleService _service = LocaleService();

  List<AppLanguage> _languages = const [];
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _offline = false;
    });

    try {
      final languages = await _service.fetchLanguages();
      if (!mounted) return;
      setState(() {
        _languages = languages.isEmpty ? _fallbackLanguages : languages;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _languages = _fallbackLanguages;
        _offline = true;
        _loading = false;
      });
    }
  }

  Future<void> _choose(String? code) async {
    await LocaleController.instance.setLocale(code);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);
    final l10n = AppLocalizations.of(context);
    final selected = LocaleController.instance.code;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(l10n.languageTitle),
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      l10n.languageSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ),
                  if (_offline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.languageLoadError,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  _tile(
                    isDark,
                    title: l10n.languageSystem,
                    subtitle: null,
                    selectedValue: selected == null,
                    onTap: () => _choose(null),
                  ),
                  ..._languages.map(
                    (language) => _tile(
                      isDark,
                      title: language.nativeName.isEmpty
                          ? language.name
                          : language.nativeName,
                      subtitle: language.name,
                      selectedValue: selected == language.code,
                      onTap: () => _choose(language.code),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _tile(
    bool isDark, {
    required String title,
    required String? subtitle,
    required bool selectedValue,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2733) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
        trailing: selectedValue
            ? const Icon(Icons.check_circle, color: Color(0xFF00A651))
            : Icon(
                Icons.circle_outlined,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
      ),
    );
  }

  static const List<AppLanguage> _fallbackLanguages = [
    AppLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      direction: 'ltr',
      isDefault: true,
    ),
    AppLanguage(
      code: 'ps',
      name: 'Pashto',
      nativeName: 'پښتو',
      direction: 'rtl',
      isDefault: false,
    ),
    AppLanguage(
      code: 'fa',
      name: 'Dari',
      nativeName: 'دری',
      direction: 'rtl',
      isDefault: false,
    ),
  ];
}
