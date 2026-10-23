import 'package:vortex_app/routes/app_router.dart';

/// Opens the screen a tapped notification points at.
///
/// One place decides where a notification leads, so an in-app tap and a push
/// tap land in the same spot instead of drifting apart. The server sends the
/// order reference inside the notification's `data`, so an order update opens
/// the customer's orders; anything without a destination is left alone.
class NotificationNavigator {
  NotificationNavigator._();

  /// [data] is the notification's `data` map (order_id, order_number, status).
  /// [type] is the notification type, e.g. "order".
  ///
  /// [openFallback] sends an unrecognised notification to the notification
  /// centre. That is wanted for a push tap (the app was closed, so any landing
  /// screen is an improvement) but not for an in-app tap, where the person is
  /// already looking at that same list.
  static void handle(
    Map<String, dynamic> data, {
    String? type,
    bool openFallback = false,
  }) {
    final isOrder = (type != null && type.startsWith('order')) ||
        data['order_id'] != null ||
        data['order_number'] != null;

    if (isOrder) {
      _push(AppRouter.orderList);
      return;
    }

    if (openFallback) {
      _push(AppRouter.notifications);
    }
  }

  /// Push once the navigator exists. A push that opens the app from cold can
  /// arrive before the first frame, so wait for the navigator instead of
  /// dropping the tap.
  ///
  /// The route is forced onto the root navigator so a tap always lands on a
  /// full screen, never buried inside a tab. If that route is already on top
  /// (for example the customer is already on their notifications), pushing the
  /// same name again would look like nothing happened -- so it is skipped.
  static void _push(String route, {int attempts = 30}) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      if (attempts <= 0) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        _push(route, attempts: attempts - 1);
      });
      return;
    }

    if (AppRouter.currentRoute == route) {
      return;
    }

    AppRouter.currentRoute = route;
    navigator.pushNamed(route);
  }
}
