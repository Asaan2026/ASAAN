import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/service_model.dart';

/// Reads the shop's bookable services and places bookings.
///
/// The app reads the same models and settings the storefront does, so a slot
/// that is full on the website is full here too. Nothing is duplicated here
/// beyond the JSON shape.
class ServiceCatalogService {
  final ApiClient _apiClient;

  ServiceCatalogService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// A page of published services, optionally filtered or searched.
  Future<ServiceCatalogPage> fetchServices({
    String? search,
    String? category,
    bool featured = false,
    String? sort,
    int page = 1,
    int perPage = 12,
  }) async {
    final response = await _apiClient.get(
      ApiConfig.services,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.isNotEmpty) 'category': category,
        if (featured) 'featured': '1',
        if (sort != null && sort.isNotEmpty) 'sort': sort,
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    _ensureSuccess(response, 'SERVICES_FAILED');

    final items = (response['data'] as List<dynamic>? ?? const [])
        .map((item) => ServiceItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = response['meta'] as Map<String, dynamic>? ?? const {};

    return ServiceCatalogPage(
      items: items,
      currentPage: _asInt(meta['current_page']),
      lastPage: _asInt(meta['last_page']),
    );
  }

  /// Every category a customer can browse.
  Future<List<ServiceCategory>> fetchCategories() async {
    final response = await _apiClient.get(ApiConfig.serviceCategories);

    _ensureSuccess(response, 'SERVICE_CATEGORIES_FAILED');

    return (response['data'] as List<dynamic>? ?? const [])
        .map((item) => ServiceCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// One service with its booking window and settings.
  Future<ServiceDetail> fetchDetail(String slug) async {
    final response = await _apiClient.get(ApiConfig.serviceDetail(slug));

    _ensureSuccess(response, 'SERVICE_DETAIL_FAILED');

    return ServiceDetail.fromJson(
      response['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// The slots and dates for the picker.
  Future<ServiceSlots> fetchSlots(String slug) async {
    final response = await _apiClient.get(ApiConfig.serviceSlots(slug));

    _ensureSuccess(response, 'SERVICE_SLOTS_FAILED');

    return ServiceSlots.fromJson(
      response['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Place a booking. A refusal (full slot, closed window, missing field)
  /// arrives as a 422 thrown by the client, carrying the field it belongs to.
  Future<ServiceBookingResult> book(
    String slug,
    Map<String, dynamic> fields,
  ) async {
    final response = await _apiClient.post(
      ApiConfig.serviceBook(slug),
      body: fields,
    );

    _ensureSuccess(response, 'SERVICE_BOOKING_FAILED');

    return ServiceBookingResult.fromJson(
      response['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  void _ensureSuccess(Map<String, dynamic> response, String fallbackCode) {
    if (response['success'] == false) {
      throw ApiException(
        message: response['message'] as String? ?? 'The request failed.',
        code: response['error_code'] as String? ?? fallbackCode,
        errors: response['errors'] as Map<String, dynamic>?,
      );
    }
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
