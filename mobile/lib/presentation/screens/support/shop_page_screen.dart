import 'package:flutter/material.dart';
import 'package:vortex_app/data/services/page_service.dart';
import 'package:vortex_app/l10n/app_localizations.dart';
import 'package:vortex_app/presentation/widgets/html_text.dart';

/// Shows one of the shop's own pages — about us, privacy policy, terms —
/// exactly as the dashboard holds it.
///
/// These three screens used to carry their text in the app's code: nobody
/// could correct them, and they said different things from the same pages on
/// the website. One screen reads whichever page it is pointed at, so editing
/// the page in the dashboard changes it in both places at once.
class ShopPageScreen extends StatefulWidget {
  const ShopPageScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  /// The page's address in the dashboard, such as "privacy-policy".
  final String slug;

  /// Shown in the header while the page loads, and if it has no title of its
  /// own.
  final String title;

  @override
  State<ShopPageScreen> createState() => _ShopPageScreenState();
}

class _ShopPageScreenState extends State<ShopPageScreen> {
  final PageService _pages = PageService();

  ShopPage? _page;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final page = await _pages.fetch(widget.slug);
      if (!mounted) return;
      setState(() {
        _page = page;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final page = _page;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
        elevation: 0,
        title: Text(
          page?.title.isNotEmpty == true ? page!.title : widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_failed)
              _message(l10n.shopPageLoadError, isDark)
            else if (page == null || page.isEmpty)
              _message(l10n.shopPageEmpty, isDark)
            else
              HtmlText(
                html: page.content,
                baseStyle: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
                linkColor:
                    isDark ? Colors.lightBlue.shade200 : Colors.blue.shade700,
              ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
