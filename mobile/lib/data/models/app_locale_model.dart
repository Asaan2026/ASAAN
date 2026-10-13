/// One language the app can be shown in.
///
/// Comes from the server's `/api/v1/locales`, so the list and the default are
/// owned in one place rather than hard-coded here.
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String direction;
  final bool isDefault;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.direction,
    required this.isDefault,
  });

  factory AppLanguage.fromJson(Map<String, dynamic> json) {
    return AppLanguage(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nativeName: json['native_name']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'ltr',
      isDefault: json['is_default'] == true,
    );
  }

  bool get isRtl => direction.toLowerCase() == 'rtl';
}
