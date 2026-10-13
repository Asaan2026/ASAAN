import 'dart:io';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/api_response.dart';
import '../models/identity_status_model.dart';

/// The customer's Tazkira verification, for the mobile app.
///
/// Talks to the same endpoints as the website. The anti-fraud rules live on the
/// server, so nothing here tries to re-implement them — the app just sends the
/// fields and shows the state the server returns.
class IdentityService {
  final ApiClient _apiClient;

  IdentityService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// The signed-in customer's current verification state.
  Future<IdentityStatus> fetchStatus() async {
    final response = await _apiClient.get(ApiConfig.identity);

    return _parse(response, 'IDENTITY_STATUS_FAILED');
  }

  /// Send a Tazkira for review.
  Future<IdentityStatus> submit({
    required String nationalId,
    required String fullName,
    String? fatherName,
    String? dateOfBirth,
    required File image,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiConfig.identity,
      fields: {
        'national_id': nationalId.trim(),
        'full_name': fullName.trim(),
        if (fatherName != null && fatherName.trim().isNotEmpty)
          'father_name': fatherName.trim(),
        if (dateOfBirth != null && dateOfBirth.isNotEmpty)
          'date_of_birth': dateOfBirth,
      },
      files: {'image': image},
    );

    return _parse(response, 'IDENTITY_SUBMIT_FAILED');
  }

  IdentityStatus _parse(Map<String, dynamic> response, String fallbackCode) {
    if (response['success'] == false) {
      throw ApiException(
        message: response['message'] as String? ?? 'Identity request failed',
        code: response['error_code'] as String? ?? fallbackCode,
        errors: response['errors'] as Map<String, dynamic>?,
      );
    }

    final apiResponse = ApiResponse<IdentityStatus>.fromJson(
      response,
      (data) => IdentityStatus.fromJson(data as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message,
        code: apiResponse.errorCode ?? fallbackCode,
      );
    }

    return apiResponse.data!;
  }
}
