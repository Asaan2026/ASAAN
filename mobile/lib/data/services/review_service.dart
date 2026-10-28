import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

/// Sending a customer's review of something they bought.
///
/// The shop reads every review before it appears, so a review submitted here
/// is waiting for approval rather than live. The app says so, because a
/// customer who writes a review and never sees it assumes the app lost it.
class ReviewService {
  ReviewService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> submit({
    required int productId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    final response = await _apiClient.post(
      '/api/${ApiConfig.apiVersion}/reviews',
      body: {
        'product_id': productId,
        'rating': rating,
        'title': title,
        'comment': comment,
      },
    );

    if (response['success'] != true) {
      throw ApiException(
        message: response['message'] ?? 'Your review could not be sent',
        code: response['error_code'] ?? 'REVIEW_FAILED',
      );
    }
  }
}
