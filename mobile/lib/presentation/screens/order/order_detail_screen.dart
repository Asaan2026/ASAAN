import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vortex_app/core/constants/app_colors.dart';
import 'package:vortex_app/data/services/order_service.dart';
import 'package:vortex_app/presentation/widgets/price_text.dart';

/// One of the customer's own orders.
///
/// The order list hands over the few facts it already has so the page paints
/// immediately, then the full order is fetched: the items, the address it is
/// going to, how it was paid for and what it added up to. Everything shown
/// here comes from that order — a section with nothing behind it is left out
/// rather than filled in with an example.
class OrderDetailScreen extends StatefulWidget {
  final int? orderId;
  final String orderNumber;
  final String orderDate;
  final String orderStatus;
  final double totalAmount;

  const OrderDetailScreen({
    super.key,
    this.orderId,
    required this.orderNumber,
    required this.orderDate,
    required this.orderStatus,
    required this.totalAmount,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();

  Order? _order;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final id = widget.orderId;
    if (id == null || id == 0) return;

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final order = await _orderService.getOrderDetail(id);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'We could not load this order. Pull down to try again.';
      });
    }
  }

  // --------------------------------------------------------------- helpers --

  Color get _cardColor =>
      _isDark ? const Color(0xFF1A2632) : Colors.white;

  Color get _borderColor =>
      _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  Color get _mutedTextColor =>
      _isDark ? Colors.grey.shade400 : Colors.grey.shade600;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      );

  String? _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
  }

  String? _formatDay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat.yMMMd().format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadOrder,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: isDark
                      ? const Color(0xFF101922)
                      : const Color(0xFFF6F7F8),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text(
                    'Order Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      children: [
                        _buildOrderInfoCard(isDark),
                        const SizedBox(height: 16),
                        _buildStatusCard(isDark),
                        const SizedBox(height: 16),
                        _buildItemsCard(isDark),
                        ..._buildAddressAndPayment(isDark),
                        const SizedBox(height: 16),
                        _buildOrderSummaryCard(isDark),
                        if (_loadError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: _mutedTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ order info --

  Widget _buildOrderInfoCard(bool isDark) {
    final order = _order;
    final number = order?.orderNumber ?? widget.orderNumber;
    final date = _formatDate(order?.createdAt) ?? widget.orderDate;
    final status = (order?.statusLabel.isNotEmpty ?? false)
        ? order!.statusLabel
        : (order?.status ?? widget.orderStatus);
    final shipment = order?.shipments.isNotEmpty == true
        ? order!.shipments.first
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style:
                            TextStyle(fontSize: 14, color: _mutedTextColor),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark ? Colors.blue.shade800 : Colors.blue.shade100,
                  ),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.blue.shade300 : AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          // Tracking, only when the shop has actually recorded a dispatch.
          if (shipment != null &&
              (shipment.trackingNumber != null ||
                  shipment.carrier != null)) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: _borderColor),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.local_shipping,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shipment.carrier != null)
                        Text(
                          shipment.carrier!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (shipment.trackingNumber != null)
                        Text(
                          'Tracking: ${shipment.trackingNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _mutedTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- status --

  /// Where the order has got to, worked out from its real status. Each step
  /// carries a date only where the order actually records one.
  Widget _buildStatusCard(bool isDark) {
    final order = _order;
    final status = (order?.status ?? widget.orderStatus).toLowerCase();

    if (status.contains('cancel')) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration,
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Text(
              'This order was cancelled.',
              style: TextStyle(fontSize: 14, color: _mutedTextColor),
            ),
          ],
        ),
      );
    }

    const steps = ['Order Placed', 'Processing', 'Shipped', 'Delivered'];
    final reached = switch (status) {
      final s when s.contains('deliver') || s.contains('complete') => 3,
      final s when s.contains('ship') => 2,
      final s when s.contains('process') || s.contains('confirm') => 1,
      _ => 0,
    };

    final shipment =
        order?.shipments.isNotEmpty == true ? order!.shipments.first : null;
    final dates = <int, String?>{
      0: _formatDate(order?.createdAt) ??
          (widget.orderDate.isEmpty ? null : widget.orderDate),
      2: _formatDate(shipment?.shippedAt),
      3: shipment?.estimatedDelivery != null && reached < 3
          ? 'Estimated ${_formatDay(shipment!.estimatedDelivery)}'
          : null,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++)
            _buildTimelineStep(
              steps[i],
              dates[i],
              i <= reached,
              i == reached,
              isDark,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String? subtitle,
    bool done,
    bool current,
    bool isDark, {
    bool isLast = false,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF334155) : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? activeColor : inactiveColor,
              ),
              child: done
                  ? Icon(
                      current ? Icons.autorenew : Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: done ? activeColor : inactiveColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    color: done
                        ? (isDark ? Colors.white : Colors.grey.shade900)
                        : _mutedTextColor,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: _mutedTextColor),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- items --

  Widget _buildItemsCard(bool isDark) {
    final order = _order;

    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              order == null
                  ? 'Items'
                  : (order.items.length == 1
                      ? '1 item'
                      : '${order.items.length} items'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1, color: _borderColor),
          if (order == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Items are not available for this order.',
                        style:
                            TextStyle(fontSize: 13, color: _mutedTextColor),
                      ),
              ),
            )
          else if (order.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No items were recorded on this order.',
                  style: TextStyle(fontSize: 13, color: _mutedTextColor),
                ),
              ),
            )
          else
            for (var i = 0; i < order.items.length; i++)
              _buildOrderItem(
                order.items[i],
                isDark,
                i < order.items.length - 1,
              ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, bool isDark, bool showDivider) {
    final image = item.productImage;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image == null || image.isEmpty
                      ? Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade400,
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StyledPriceText(
                          amount: item.price,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    if (item.productSku != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.productSku}',
                        style:
                            TextStyle(fontSize: 12, color: _mutedTextColor),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(fontSize: 12, color: _mutedTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: _borderColor),
      ],
    );
  }

  // ------------------------------------------------- address and payment --

  List<Widget> _buildAddressAndPayment(bool isDark) {
    final order = _order;
    if (order == null) return const [];

    final address = order.shippingAddress ?? order.billingAddress;
    final payment = order.paymentMethodTitle;

    final cards = <Widget>[];

    if (address != null && !address.isEmpty) {
      cards.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 18, color: _mutedTextColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Shipping Address',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (address.fullName.isNotEmpty)
                Text(
                  address.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (address.formatted.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  address.formatted,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _mutedTextColor,
                  ),
                ),
              ],
              if (address.phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  address.phone!,
                  style: TextStyle(fontSize: 13, color: _mutedTextColor),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (payment != null) {
      cards.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 18, color: _mutedTextColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Payment Method',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                payment,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (order.paymentStatus != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Payment ${order.paymentStatus}',
                  style: TextStyle(fontSize: 13, color: _mutedTextColor),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return [
      for (final card in cards) ...[const SizedBox(height: 16), card],
    ];
  }

  // --------------------------------------------------------------- summary --

  Widget _buildOrderSummaryCard(bool isDark) {
    final order = _order;
    final total = order?.total ?? widget.totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (order != null) ...[
            if (order.subtotal > 0) ...[
              _buildSummaryRow('Subtotal', order.subtotal, isDark),
              const SizedBox(height: 8),
            ],
            if (order.shippingCost > 0) ...[
              _buildSummaryRow('Shipping', order.shippingCost, isDark),
              const SizedBox(height: 8),
            ],
            if (order.tax > 0) ...[
              _buildSummaryRow('Tax', order.tax, isDark),
              const SizedBox(height: 8),
            ],
            if (order.discount > 0) ...[
              _buildSummaryRow('Discount', -order.discount, isDark),
              const SizedBox(height: 8),
            ],
            Divider(height: 1, color: _borderColor),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              StyledPriceText(
                amount: total,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue.shade400 : AppColors.primary,
              ),
            ],
          ),
          if (order?.customerNote != null) ...[
            const SizedBox(height: 12),
            Text(
              'Your note: ${order!.customerNote}',
              style: TextStyle(fontSize: 13, color: _mutedTextColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: _mutedTextColor),
        ),
        StyledPriceText(
          amount: amount,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  // ------------------------------------------------------------ bottom bar --

  Widget _buildBottomBar(bool isDark) {
    final canCancel = _order?.canCancel ?? false;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Row(
          children: [
            if (canCancel) ...[
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Cancel order feature coming soon...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      side: BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reorder feature coming soon...'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.replay, size: 20),
                  label: const Text(
                    'Reorder',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
