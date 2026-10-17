import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/app_notification_model.dart';
import '../../../data/services/notification_service.dart';
import '../../../l10n/app_localizations.dart';

/// The customer's notifications, opened from the home-screen bell.
///
/// The server owns the wording of every message, so the app never invents an
/// order update; it only shows what arrived and tells the server which ones
/// were read, which keeps the bell badge honest.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();

  List<AppNotification> _items = const [];
  bool _loading = true;
  bool _markingAll = false;
  String? _error;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool get _hasUnread => _items.any((item) => !item.read);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
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
        _error = _l10n.notificationsLoadError;
        _loading = false;
      });
    }
  }

  Future<void> _openNotification(AppNotification item) async {
    if (item.read) return;

    // Show it as read straight away so the list feels instant; put it back if
    // the server refuses, so the badge and the list never drift apart.
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) return;

    final previous = _items[index];
    setState(() {
      _items = List.of(_items)
        ..[index] = previous.copyWith(read: true, readAt: DateTime.now());
    });

    try {
      final updated = await _service.markAsRead(item.id);
      if (!mounted) return;
      setState(() {
        final current = _items.indexWhere((entry) => entry.id == item.id);
        if (current >= 0) {
          _items = List.of(_items)..[current] = updated;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final current = _items.indexWhere((entry) => entry.id == item.id);
        if (current >= 0) {
          _items = List.of(_items)..[current] = previous;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_markingAll || !_hasUnread) return;

    setState(() => _markingAll = true);

    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((item) => item.read
                ? item
                : item.copyWith(read: true, readAt: DateTime.now()))
            .toList();
        _markingAll = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.notificationsAllRead)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.commonError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(_l10n.notificationsTitle),
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          if (_hasUnread)
            TextButton(
              onPressed: _markingAll ? null : _markAllAsRead,
              child: _markingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_l10n.notificationsMarkAllRead),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(isDark),
        ),
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
          const SizedBox(height: 120),
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
                      onPressed: _load, child: Text(_l10n.commonTryAgain)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 56,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _l10n.notificationsEmptyTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _l10n.notificationsEmptyBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCard(_items[index], isDark),
    );
  }

  Widget _buildCard(AppNotification item, bool isDark) {
    final unread = !item.read;
    final when = _formatDate(item.createdAt);

    return InkWell(
      onTap: () => _openNotification(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18222C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unread
                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE))
                : (isDark ? const Color(0xFF243040) : const Color(0xFFE6E9EC)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1B2733) : const Color(0xFFEFF3F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconFor(item.type),
                size: 18,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                unread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (when.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      when,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order_status':
      case 'order_placed':
        return Icons.local_shipping_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return DateFormat('MMM d, HH:mm').format(value.toLocal());
  }
}
