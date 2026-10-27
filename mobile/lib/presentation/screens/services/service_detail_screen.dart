import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/service_catalog_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../../widgets/html_text.dart';

/// Everything about one service, and the way in to booking it.
class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ServiceCatalogService _service = ServiceCatalogService();

  ServiceDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _service.fetchDetail(widget.slug);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _l10n.servicesDetailLoadError;
        _loading = false;
      });
    }
  }

  void _startBooking(ServiceItem service) {
    Navigator.pushNamed(
      context,
      AppRouter.serviceBooking,
      arguments: {'slug': service.slug, 'serviceName': service.name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(_l10n.servicesDetailsTitle),
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(child: _buildBody(isDark)),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: Text(_l10n.commonTryAgain)),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final service = detail.service;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildHero(service, isDark),
        const SizedBox(height: 16),
        _buildMeta(service, isDark),
        const SizedBox(height: 16),
        if ((service.description ?? '').isNotEmpty) ...[
          _sectionLabel(_l10n.servicesAbout, isDark),
          const SizedBox(height: 8),
          HtmlText(
            html: service.description!,
            baseStyle: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            linkColor: isDark ? Colors.lightBlue.shade200 : Colors.blue.shade700,
          ),
          const SizedBox(height: 20),
        ],
        if (service.includes.isNotEmpty) ...[
          _buildListCard(
              _l10n.servicesIncluded, service.includes, isDark, true),
          const SizedBox(height: 16),
        ],
        if (service.excludes.isNotEmpty) ...[
          _buildListCard(
              _l10n.servicesExcluded, service.excludes, isDark, false),
          const SizedBox(height: 16),
        ],
        _buildBookingCard(_detail!, isDark),
        if (_detail!.related.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel(_l10n.servicesAlsoNeed, isDark),
          const SizedBox(height: 12),
          ..._detail!.related.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRelatedCard(item, isDark),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHero(ServiceItem service, bool isDark) {
    final imageUrl = service.imageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? const Color(0xFF1B2733) : Colors.white,
                  child: const Center(
                    child: Icon(Icons.build_outlined,
                        size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        if (imageUrl != null && imageUrl.isNotEmpty) const SizedBox(height: 16),
        Text(
          service.name,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              service.priceText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00A651),
              ),
            ),
            if (service.featured) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _l10n.servicesFeatured,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A6D00),
                  ),
                ),
              ),
            ],
          ],
        ),
        if ((service.priceNote ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            service.priceNote!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMeta(ServiceItem service, bool isDark) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (service.category != null)
          _metaChip(Icons.category_outlined, service.category!.name),
        if ((service.durationDisplay ?? '').isNotEmpty)
          _metaChip(Icons.schedule, service.durationDisplay!),
        if ((service.serviceArea ?? '').isNotEmpty)
          _metaChip(Icons.place_outlined, service.serviceArea!),
      ],
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isDark ? Colors.white54 : Colors.black45),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListCard(
      String title, List<String> items, bool isDark, bool positive) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(title, isDark),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    positive ? Icons.check_circle : Icons.remove_circle_outline,
                    size: 18,
                    color: positive
                        ? const Color(0xFF00A651)
                        : (isDark ? Colors.white38 : Colors.black38),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(ServiceDetail detail, bool isDark) {
    final booking = detail.booking;
    final settings = detail.settings;

    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(_l10n.servicesBooking, isDark),
          const SizedBox(height: 8),
          if (!booking.enabled)
            Text(
              _l10n.servicesInfoOnly,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            )
          else ...[
            if ((settings.coverageNote ?? '').isNotEmpty) ...[
              Text(
                settings.coverageNote!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startBooking(detail.service),
                icon: const Icon(Icons.event_available, size: 18),
                label: Text(_l10n.servicesBookButton),
              ),
            ),
          ],
          if ((settings.contactPhone ?? '').isNotEmpty ||
              (settings.contactWhatsapp ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              [
                if ((settings.contactPhone ?? '').isNotEmpty)
                  _l10n.servicesContactCall(settings.contactPhone!),
                if ((settings.contactWhatsapp ?? '').isNotEmpty)
                  _l10n.servicesContactWhatsapp(settings.contactWhatsapp!),
              ].join('  ·  '),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedCard(ServiceItem service, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.serviceDetail,
        arguments: {'slug': service.slug},
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2733) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.priceText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF00A651),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2733) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
