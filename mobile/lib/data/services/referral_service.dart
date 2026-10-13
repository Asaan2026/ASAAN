import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/api_response.dart';
import '../models/referral_model.dart';

/// The referral programme for the mobile app.
///
/// Talks to the same endpoints the website already runs. The rules live on the
/// server, so nothing here re-implements them; the app sends a code and shows
/// the answer it gets back.
class ReferralService {
  final ApiClient _apiClient;

  ReferralService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// The customer's code, balance and invited friends.
  Future<ReferralSummary> fetchSummary() async {
    final response = await _apiClient.get(ApiConfig.referrals);

    if (response['success'] == false) {
      throw ApiException(
        message: response['message'] as String? ?? 'Could not load referrals',
        code: response['error_code'] as String? ?? 'REFERRALS_FAILED',
      );
    }

    final parsed = ApiResponse<ReferralSummary>.fromJson(
      response,
      (data) => ReferralSummary.fromJson(data as Map<String, dynamic>),
    );

    if (!parsed.success || parsed.data == null) {
      throw ApiException(
        message: parsed.message,
        code: parsed.errorCode ?? 'REFERRALS_FAILED',
      );
    }

    return parsed.data!;
  }

  /// The credit history, newest first.
  Future<List<ReferralLedgerEntry>> fetchLedger({int perPage = 20}) async {
    final response = await _apiClient.get(
      ApiConfig.referralsLedger,
      queryParameters: {'per_page': '$perPage'},
    );

    if (response['success'] == false) {
      throw ApiException(
        message:
            response['message'] as String? ?? 'Could not load credit history',
        code: response['error_code'] as String? ?? 'REFERRAL_LEDGER_FAILED',
      );
    }

    final entries = response['data'] as List<dynamic>? ?? const [];

    return entries
        .map((entry) =>
            ReferralLedgerEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  /// Apply a friend's referral code to this account.
  ///
  /// A refusal arrives as a 422 and is thrown as an [ApiException] carrying the
  /// server's plain-English reason, which the screen shows under the field.
  Future<void> applyCode(String code) async {
    final response = await _apiClient.post(
      ApiConfig.referralsApply,
      body: {'code': code.trim()},
    );

    if (response['success'] == false) {
      throw ApiException(
        message: response['message'] as String? ?? 'Could not apply the code',
        code: response['error_code'] as String? ?? 'REFERRAL_REFUSED',
        errors: response['errors'] as Map<String, dynamic>?,
      );
    }
  }
}
