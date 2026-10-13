import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/app_locale_model.dart';

/// Reads the languages the shop publishes.
///
/// The list is owned by the server so a language added there appears in the
/// app without a new release.
class LocaleService {
  final ApiClient _apiClient;

  LocaleService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<AppLanguage>> fetchLanguages() async {
    final response = await _apiClient.get(ApiConfig.locales);

    if (response['success'] == false) {
      throw ApiException(
        message: response['message'] as String? ?? 'The request failed.',
        code: response['error_code'] as String? ?? 'LOCALES_FAILED',
      );
    }

    return (response['data'] as List<dynamic>? ?? const [])
        .map((item) => AppLanguage.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
