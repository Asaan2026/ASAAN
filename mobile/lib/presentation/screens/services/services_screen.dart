import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/service_catalog_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_router.dart';
import '../../widgets/html_text.dart';

/// The list of jobs the shop offers, grouped by category and searchable.
///
/// Tapping one opens its detail page, which is where booking happens.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServiceCatalogService _service = ServiceCatalogService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ServiceCategory> _categories = const [];
  final List<ServiceItem> _services = [];
  String? _selectedCategory;
  String _search = '';
  int _page = 1;
  int _lastPage = 1;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  bool get _hasMore => _page < _lastPage;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _service.fetchCategories();
      final page = await _fetchFirstPage();

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _services
          ..clear()
          ..addAll(page.items);
        _page = page.currentPage;
        _lastPage = page.lastPage;
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
        _error = _l10n.servicesLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _reloadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await _fetchFirstPage();
      if (!mounted) return;
      setState(() {
        _services
          ..clear()
          ..addAll(page.items);
        _page = page.currentPage;
        _lastPage = page.lastPage;
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
        _error = _l10n.servicesLoadError;
        _loading = false;
      });
    }
  }

  Future<ServiceCatalogPage> _fetchFirstPage() {
    return _service.fetchServices(
      search: _search,
      category: _selectedCategory,
    );
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final page = await _service.fetchServices(
        search: _search,
        category: _selectedCategory,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _services.addAll(page.items);
        _page = page.currentPage;
        _lastPage = page.lastPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchSubmitted(String value) {
    _search = value.trim();
    _reloadServices();
  }

  void _onCategorySelected(String? slug) {
    if (_selectedCategory == slug) return;
    setState(() => _selectedCategory = slug);
    _reloadServices();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(_l10n.servicesTitle),
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearch(isDark),
            _buildCategoryChips(isDark),
            Expanded(child: _buildBody(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSearchSubmitted,
        decoration: InputDecoration(
          hintText: _l10n.servicesSearchHint,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: isDark ? const Color(0xFF1B2733) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(isDark,
              label: _l10n.servicesAll,
              selected: _selectedCategory == null,
              onTap: () => _onCategorySelected(null)),
          ..._categories.map(
            (category) => _chip(
              isDark,
              label: category.name,
              selected: _selectedCategory == category.slug,
              onTap: () => _onCategorySelected(category.slug),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    bool isDark, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 13,
          color: selected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
        ),
        selectedColor: const Color(0xFF00A651),
        backgroundColor: isDark ? const Color(0xFF1B2733) : Colors.white,
        showCheckmark: false,
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _bootstrap,
                    child: Text(_l10n.commonTryAgain),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_services.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Icon(Icons.build_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _l10n.servicesEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _reloadServices,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _services.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _services.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildServiceCard(_services[index], isDark);
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service, bool isDark) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ServiceThumb(service: service),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if ((service.shortDescription ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    HtmlText(
                      html: service.shortDescription!,
                      maxLines: 2,
                      baseStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    service.priceText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
}

/// The little square that stands in for a service photo.
class _ServiceThumb extends StatelessWidget {
  const _ServiceThumb({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = service.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 64,
        height: 64,
        color: isDark ? const Color(0xFF101922) : const Color(0xFFEFF3F6),
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(
                Icons.build_outlined,
                color: isDark ? Colors.white38 : Colors.black26,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.build_outlined,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ),
      ),
    );
  }
}
