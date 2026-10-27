import 'package:vortex_app/core/config/api_config.dart';
import 'package:vortex_app/core/network/api_client.dart';
import 'package:vortex_app/core/network/api_exception.dart';
import 'package:vortex_app/data/services/cart_service.dart';

/// Represents a single order item (one product line inside an order).
class OrderItem {
  final int id;

  /// The product this line was for. Needed to put the item back in the
  /// basket; null when the product has since been deleted.
  final int? productId;

  final String productName;
  final String? productSku;
  final String? productImage;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderItem({
    required this.id,
    this.productId,
    required this.productName,
    this.productSku,
    this.productImage,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};

    // The order line keeps its own copy of the name and picture, taken when
    // the order was placed, so the receipt still reads correctly after the
    // product has been renamed or deleted. Prefer that copy.
    final name = (json['name'] as String?)?.trim();
    final productName = (product['name'] as String?)?.trim();

    String? imageUrl = (json['image'] as String?)?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      final images = product['images'] as List<dynamic>?;
      if (images != null) {
        for (final image in images) {
          if (image is Map) {
            final url = (image['url'] ?? image['path'] ?? image['image'])
                ?.toString()
                .trim();
            if (url != null && url.isNotEmpty) {
              imageUrl = url;
              break;
            }
          } else if (image is String && image.trim().isNotEmpty) {
            imageUrl = image.trim();
            break;
          }
        }
      }
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = (product['image'] as String?)?.trim();
      }
    }

    return OrderItem(
      id: json['id'] as int? ?? 0,
      productId: (json['product_id'] as num?)?.toInt() ??
          (product['id'] as num?)?.toInt(),
      productName: (name != null && name.isNotEmpty)
          ? name
          : (productName != null && productName.isNotEmpty
              ? productName
              : 'Product'),
      productSku: (json['sku'] as String?)?.trim(),
      productImage: (imageUrl != null && imageUrl.isEmpty) ? null : imageUrl,
      quantity: json['quantity'] as int? ?? 1,
      price: _toDouble(json['price']),
      subtotal: _toDouble(json['subtotal']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

/// Where an order is being sent, as the customer entered it.
class OrderAddress {
  final String fullName;
  final String formatted;
  final String? phone;

  const OrderAddress({
    required this.fullName,
    required this.formatted,
    this.phone,
  });

  static OrderAddress? fromJson(dynamic json) {
    if (json is! Map) return null;

    final name = (json['full_name'] ?? '').toString().trim();
    final formatted = (json['formatted_address'] ?? '').toString().trim();
    final fallback = [
      json['address_line_1'],
      json['address_line_2'],
      json['city'],
      json['state'],
      json['postal_code'],
      json['country'],
    ]
        .map((part) => part?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(', ');

    final lines = formatted.isNotEmpty ? formatted : fallback;
    if (name.isEmpty && lines.isEmpty) return null;

    final phone = (json['phone'] ?? '').toString().trim();

    return OrderAddress(
      fullName: name,
      formatted: lines,
      phone: phone.isEmpty ? null : phone,
    );
  }

  bool get isEmpty => fullName.isEmpty && formatted.isEmpty;
}

/// A dispatch of an order, when the shop has recorded one.
class OrderShipment {
  final String? carrier;
  final String? trackingNumber;
  final String? shippedAt;
  final String? estimatedDelivery;

  const OrderShipment({
    this.carrier,
    this.trackingNumber,
    this.shippedAt,
    this.estimatedDelivery,
  });

  factory OrderShipment.fromJson(Map<String, dynamic> json) {
    String? text(dynamic value) {
      final result = value?.toString().trim() ?? '';
      return result.isEmpty ? null : result;
    }

    return OrderShipment(
      carrier: text(json['carrier']),
      trackingNumber: text(json['tracking_number']),
      shippedAt: text(json['shipped_at']),
      estimatedDelivery: text(json['estimated_delivery']),
    );
  }
}

/// Represents a customer order.
class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String statusLabel;
  final double total;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double discount;
  final String currency;
  final String createdAt;
  final List<OrderItem> items;
  final String? paymentMethodTitle;
  final String? paymentStatus;
  final OrderAddress? shippingAddress;
  final OrderAddress? billingAddress;
  final List<OrderShipment> shipments;
  final String? customerNote;
  final bool canCancel;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.statusLabel = '',
    required this.total,
    this.subtotal = 0,
    this.shippingCost = 0,
    this.tax = 0,
    this.discount = 0,
    required this.currency,
    required this.createdAt,
    required this.items,
    this.paymentMethodTitle,
    this.paymentStatus,
    this.shippingAddress,
    this.billingAddress,
    this.shipments = const [],
    this.customerNote,
    this.canCancel = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    // API returns totals as a nested object: { grand_total, currency, currency_symbol, ... }
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    final payment = json['payment'] as Map<String, dynamic>? ?? {};
    return Order(
      id: json['id'] as int? ?? 0,
      orderNumber: json['order_number'] as String? ??
          json['order_no'] as String? ??
          '#${json['id']}',
      status: json['status'] as String? ?? 'pending',
      total: _toDouble(
          totals['grand_total'] ?? json['total'] ?? json['grand_total']),
      currency: totals['currency'] as String? ??
          json['currency'] as String? ??
          'USD',
      // API uses ordered_at; fall back to created_at for other shapes
      createdAt:
          json['ordered_at'] as String? ?? json['created_at'] as String? ?? '',
      items: rawItems
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusLabel: (json['status_label'] as String?)?.trim() ?? '',
      subtotal: _toDouble(totals['subtotal']),
      shippingCost: _toDouble(totals['shipping_cost']),
      tax: _toDouble(totals['tax']),
      discount: _toDouble(totals['discount']),
      paymentMethodTitle: _text(payment['method_title']) ??
          _text(payment['method']) ??
          _text(json['payment_method']),
      paymentStatus: _text(payment['status']) ?? _text(json['payment_status']),
      shippingAddress: OrderAddress.fromJson(json['shipping_address']),
      billingAddress: OrderAddress.fromJson(json['billing_address']),
      shipments: (json['shipments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderShipment.fromJson)
          .toList(),
      customerNote: _text(json['customer_note']),
      canCancel: json['can_cancel'] as bool? ?? false,
    );
  }

  static String? _text(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  int get itemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

/// Paginated result returned by [OrderService.getOrders].
class OrdersResult {
  final List<Order> orders;
  final bool hasMore;

  const OrdersResult({required this.orders, required this.hasMore});
}

/// Service for fetching the authenticated user's orders.
class OrderService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch paginated orders for the currently logged-in user.
  ///
  /// [status] — optional filter: 'pending', 'processing', 'shipped',
  ///            'delivered', 'cancelled' (null = all orders)
  /// [page]   — page number for pagination (1-based)
  Future<OrdersResult> getOrders({String? status, int page = 1}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await _apiClient.get(
        ApiConfig.customerOrders,
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> rawOrders;

        // Handle both { data: { orders: [...] } } and { data: [...] } shapes.
        if (data is List) {
          rawOrders = data;
        } else if (data is Map) {
          rawOrders = data['orders'] as List<dynamic>? ??
              data['data'] as List<dynamic>? ??
              [];
        } else {
          rawOrders = [];
        }

        final orders = rawOrders
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();

        // Use meta.current_page / meta.last_page when available.
        final meta = response['meta'] as Map<String, dynamic>?;
        bool hasMore;
        if (meta != null) {
          final currentPage = meta['current_page'] as int? ?? page;
          final lastPage = meta['last_page'] as int? ?? 1;
          hasMore = currentPage < lastPage;
        } else {
          // Fallback: if a full page came back assume there might be more.
          hasMore = orders.isNotEmpty;
        }

        return OrdersResult(orders: orders, hasMore: hasMore);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch orders');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch full detail of a single order by [orderId].
  Future<Order> getOrderDetail(int orderId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.customerOrderDetail(orderId),
      );

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          return Order.fromJson(data);
        }
        throw Exception('Unexpected response structure');
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch order details');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Ask the shop to cancel an order, and return the order as it now stands.
  ///
  /// The server only allows this while the order is still pending or
  /// processing, and it is the authority: the app hides the button in the same
  /// cases (see [Order.canCancel]), but a stale screen can still send the
  /// request, and the refusal that comes back is what the customer is shown.
  Future<Order> cancelOrder(int orderId) async {
    final response = await _apiClient.post(
      ApiConfig.customerOrderCancel(orderId),
      body: const {},
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] ?? 'This order could not be cancelled',
        code: response['error_code'] ?? 'ORDER_CANCEL_FAILED',
      );
    }

    // The reply carries the order, but not its items or addresses: those are
    // only included when the server eager-loads them, which the cancel route
    // does not. Re-read the order instead, so a cancelled order on screen does
    // not suddenly lose the things the customer ordered.
    try {
      return await getOrderDetail(orderId);
    } catch (_) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return Order.fromJson(data);
      }
      rethrow;
    }
  }

  /// Put every line of a past order back in the basket.
  ///
  /// There is no single "reorder" call on the server, so each line is added
  /// one at a time, and some may fail on their own: a product can have been
  /// withdrawn from sale, run out of stock, or been deleted outright. Each
  /// line's outcome is collected rather than letting the first failure stand
  /// for the whole order, so the customer is told exactly what could not be
  /// added and still gets everything that could.
  Future<ReorderOutcome> reorder(
    Order order, {
    AddToCart? addToCart,
  }) async {
    final add = addToCart ?? _defaultAddToCart;

    final added = <String>[];
    final failed = <ReorderFailure>[];

    for (final item in order.items) {
      final productId = item.productId;

      if (productId == null || productId == 0) {
        failed.add(ReorderFailure(
          name: item.productName,
          reason: 'This product is no longer sold',
        ));
        continue;
      }

      try {
        await add(productId: productId, quantity: item.quantity);
        added.add(item.productName);
      } on ApiException catch (e) {
        failed.add(ReorderFailure(name: item.productName, reason: e.message));
      } catch (_) {
        failed.add(ReorderFailure(
          name: item.productName,
          reason: 'Could not be added just now',
        ));
      }
    }

    return ReorderOutcome(added: added, failed: failed);
  }

  Future<void> _defaultAddToCart({
    required int productId,
    required int quantity,
  }) async {
    await CartService().addToCart(productId: productId, quantity: quantity);
  }
}

/// Adds one line to the basket. Taken as a parameter by
/// [OrderService.reorder] so the outcome handling can be tested without the
/// network.
typedef AddToCart = Future<void> Function({
  required int productId,
  required int quantity,
});

/// Why one line of a reorder could not be added.
class ReorderFailure {
  const ReorderFailure({required this.name, required this.reason});

  final String name;
  final String reason;
}

/// What came of putting a past order back in the basket.
class ReorderOutcome {
  const ReorderOutcome({required this.added, required this.failed});

  /// Names of the products now in the basket.
  final List<String> added;

  /// The lines that could not be added, each with the reason given.
  final List<ReorderFailure> failed;

  bool get isEmpty => added.isEmpty && failed.isEmpty;
  bool get allAdded => failed.isEmpty && added.isNotEmpty;
  bool get noneAdded => added.isEmpty && failed.isNotEmpty;
  bool get someAdded => added.isNotEmpty && failed.isNotEmpty;
}
