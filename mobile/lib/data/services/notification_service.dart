import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/app_notification_model.dart';

/// The customer's notifications, for the home-screen bell and its list screen.
///
/// Everything is scoped to the signed-in customer on the server, so this class
/// never passes a user id; the token the API client attaches is what decides
/// whose notifications come back.
class NotificationService {
  final ApiClient _apiClient;

  NotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// One page of notifications, newest first.
  Future<List<AppNotification>> fetchNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.notifications,
      queryParameters: {
        'page': '$page',
        'per_page': '$perPage',
        if (unreadOnly) 'unread_only': '1',
      },
    );

    if (response['success'] == false) {
      throw ApiException(
        message:
            response['message'] as String? ?? 'Could not load notifications',
        code: response['error_code'] as String? ?? 'NOTIFICATIONS_FAILED',
      );
    }

    final items = response['data'] as List<dynamic>? ?? const [];

    return items
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// The number shown on the bell.
  Future<int> fetchUnreadCount() async {
    final response = await _apiClient.get(ApiConfig.notificationsUnreadCount);

    if (response['success'] == false) {
      throw ApiException(
        message:
            response['message'] as String? ?? 'Could not load notifications',
        code: response['error_code'] as String? ?? 'NOTIFICATIONS_FAILED',
      );
    }

    return (response['data']?['unread_count'] as int?) ?? 0;
  }

  /// Mark one notification as read.
  Future<AppNotification> markAsRead(int id) async {
    final response = await _apiClient.post(ApiConfig.notificationRead(id));

    if (response['success'] == false) {
      throw ApiException(
        message:
            response['message'] as String? ?? 'Could not update notification',
        code: response['error_code'] as String? ?? 'NOTIFICATION_UPDATE_FAILED',
      );
    }

    return AppNotification.fromJson(
      response['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Mark everything as read, for the "mark all" tap.
  Future<void> markAllAsRead() async {
    final response = await _apiClient.post(ApiConfig.notificationsReadAll);

    if (response['success'] == false) {
      throw ApiException(
        message:
            response['message'] as String? ?? 'Could not update notifications',
        code: response['error_code'] as String? ?? 'NOTIFICATION_UPDATE_FAILED',
      );
    }
  }

  /// Tell the server this phone can receive push, once a push token exists.
  ///
  /// Called after login. Only useful once Firebase is set up; harmless before
  /// then because nothing calls it without a real token.
  Future<void> registerDevice(String token,
      {String platform = 'android'}) async {
    final response = await _apiClient.post(
      ApiConfig.devices,
      body: {'token': token, 'platform': platform},
    );

    if (response['success'] == false) {
      throw ApiException(
        message:
            response['message'] as String? ?? 'Could not register this device',
        code: response['error_code'] as String? ?? 'DEVICE_REGISTER_FAILED',
      );
    }
  }

  /// Forget this phone, for example on sign-out.
  Future<void> unregisterDevice(String token) async {
    await _apiClient.delete(
      ApiConfig.devices,
      body: {'token': token},
    );
  }
}
