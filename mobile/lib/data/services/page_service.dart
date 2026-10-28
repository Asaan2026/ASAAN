import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';

/// One of the shop's own pages — about us, privacy policy, terms — as written
/// in the dashboard.
class ShopPage {
  const ShopPage({required this.title, required this.content});

  final String title;

  /// HTML from the dashboard's editor. Render it; never print it.
  final String content;

  bool get isEmpty => content.trim().isEmpty;
}

/// Fetches the pages the shop owner edits in Dashboard > CMS > Pages.
///
/// The website has always read them from there. The app used to carry its own
/// copy written into the code, so the two said different things and only one
/// of them could be corrected. Both read this now.
class PageService {
  PageService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ShopPage?> fetch(String slug) async {
    final response = await _apiClient.get(
      '/api/${ApiConfig.apiVersion}/pages/$slug',
    );

    if (response['success'] != true) return null;

    final data = response['data'];
    if (data is! Map<String, dynamic>) return null;

    return ShopPage(
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
    );
  }
}
