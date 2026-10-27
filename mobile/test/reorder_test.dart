import 'package:flutter_test/flutter_test.dart';
import 'package:vortex_app/core/network/api_exception.dart';
import 'package:vortex_app/data/services/order_service.dart';

Order orderWith(List<OrderItem> items) => Order(
      id: 7,
      orderNumber: '#VX-000007',
      status: 'completed',
      total: 100,
      currency: 'AFN',
      createdAt: '2026-10-01T10:00:00Z',
      items: items,
    );

OrderItem item({
  required int id,
  int? productId,
  required String name,
  int quantity = 1,
}) =>
    OrderItem(
      id: id,
      productId: productId,
      productName: name,
      quantity: quantity,
      price: 10,
      subtotal: 10.0 * quantity,
    );

void main() {
  group('reorder', () {
    test('adds every line, with the quantity that was ordered', () async {
      final calls = <String>[];

      final outcome = await OrderService().reorder(
        orderWith([
          item(id: 1, productId: 11, name: 'Green tea', quantity: 2),
          item(id: 2, productId: 12, name: 'Honey'),
        ]),
        addToCart: ({required productId, required quantity}) async {
          calls.add('$productId x$quantity');
        },
      );

      expect(calls, ['11 x2', '12 x1']);
      expect(outcome.added, ['Green tea', 'Honey']);
      expect(outcome.failed, isEmpty);
      expect(outcome.allAdded, isTrue);
      expect(outcome.someAdded, isFalse);
    });

    test('one line failing does not stop the rest', () async {
      final outcome = await OrderService().reorder(
        orderWith([
          item(id: 1, productId: 11, name: 'Green tea'),
          item(id: 2, productId: 12, name: 'Honey'),
          item(id: 3, productId: 13, name: 'Walnuts'),
        ]),
        addToCart: ({required productId, required quantity}) async {
          if (productId == 12) {
            throw ApiException(
              message: 'Insufficient stock',
              code: 'INSUFFICIENT_STOCK',
            );
          }
        },
      );

      expect(outcome.added, ['Green tea', 'Walnuts']);
      expect(outcome.failed, hasLength(1));
      expect(outcome.someAdded, isTrue);
    });

    test("passes on the shop's own reason for refusing a line", () async {
      final outcome = await OrderService().reorder(
        orderWith([item(id: 1, productId: 11, name: 'Honey')]),
        addToCart: ({required productId, required quantity}) async {
          throw ApiException(
            message: 'Product not available',
            code: 'PRODUCT_UNAVAILABLE',
          );
        },
      );

      expect(outcome.noneAdded, isTrue);
      expect(outcome.failed.single.name, 'Honey');
      expect(outcome.failed.single.reason, 'Product not available');
    });

    test('a deleted product is reported, and never sent to the basket',
        () async {
      var called = false;

      final outcome = await OrderService().reorder(
        orderWith([item(id: 1, productId: null, name: 'Old blend')]),
        addToCart: ({required productId, required quantity}) async {
          called = true;
        },
      );

      expect(called, isFalse);
      expect(outcome.added, isEmpty);
      expect(outcome.failed.single.name, 'Old blend');
      expect(outcome.failed.single.reason, 'This product is no longer sold');
    });

    test('an unexpected failure still names the item', () async {
      final outcome = await OrderService().reorder(
        orderWith([item(id: 1, productId: 11, name: 'Honey')]),
        addToCart: ({required productId, required quantity}) async {
          throw StateError('socket closed');
        },
      );

      expect(outcome.failed.single.name, 'Honey');
      expect(outcome.failed.single.reason, 'Could not be added just now');
      expect(outcome.failed.single.reason, isNot(contains('socket')));
    });

    test('an order with no lines gives nothing to report', () async {
      final outcome = await OrderService().reorder(
        orderWith([]),
        addToCart: ({required productId, required quantity}) async {},
      );

      expect(outcome.isEmpty, isTrue);
      expect(outcome.allAdded, isFalse);
      expect(outcome.noneAdded, isFalse);
    });
  });

  group('order item', () {
    test('keeps the product id so the line can be reordered', () {
      final parsed = OrderItem.fromJson({
        'id': 5,
        'product_id': 42,
        'name': 'Green tea',
        'quantity': 3,
        'price': 50,
        'subtotal': 150,
      });

      expect(parsed.productId, 42);
      expect(parsed.productName, 'Green tea');
      expect(parsed.quantity, 3);
    });

    test('falls back to the nested product id', () {
      final parsed = OrderItem.fromJson({
        'id': 5,
        'product': {'id': 42, 'name': 'Green tea'},
        'quantity': 1,
      });

      expect(parsed.productId, 42);
      expect(parsed.productName, 'Green tea');
    });

    test('no product id at all leaves it null rather than guessing', () {
      final parsed = OrderItem.fromJson({'id': 5, 'name': 'Gone', 'quantity': 1});

      expect(parsed.productId, isNull);
    });
  });

  group('order cancel rule', () {
    test('mirrors the server: only a pending or processing order can stop', () {
      // The server allows cancelling for exactly these statuses, and sends
      // can_cancel to match; the app must not offer the button otherwise.
      Order withCanCancel(bool value) => Order(
            id: 1,
            orderNumber: '#1',
            status: 'pending',
            total: 1,
            currency: 'AFN',
            createdAt: '',
            items: const [],
            canCancel: value,
          );

      expect(withCanCancel(true).canCancel, isTrue);
      expect(withCanCancel(false).canCancel, isFalse);
      expect(
        Order.fromJson({'id': 1, 'status': 'shipped'}).canCancel,
        isFalse,
        reason: 'an order the server says nothing about must not offer cancel',
      );
      expect(
        Order.fromJson({'id': 1, 'status': 'pending', 'can_cancel': true})
            .canCancel,
        isTrue,
      );
    });
  });
}
