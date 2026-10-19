/// The shop's public contact details.
///
/// Mirrors GET /api/v1/storefront/contact. The numbers and links are set in the
/// dashboard, so they are read from the server rather than hard-coded in the app.
class StoreContact {
  final String whatsapp;
  final bool whatsappEnabled;
  final String whatsappMessage;
  final String phone;
  final String email;
  final String playStoreUrl;
  final String appStoreUrl;

  const StoreContact({
    this.whatsapp = '',
    this.whatsappEnabled = true,
    this.whatsappMessage = 'Hello Asaan Store, ',
    this.phone = '',
    this.email = '',
    this.playStoreUrl = '',
    this.appStoreUrl = '',
  });

  factory StoreContact.fromJson(Map<String, dynamic> json) {
    return StoreContact(
      whatsapp: json['whatsapp']?.toString() ?? '',
      // Older servers do not send this field; missing means "show it", so the
      // button keeps working until the dashboard is upgraded.
      whatsappEnabled: json['whatsapp_enabled'] == null
          ? true
          : json['whatsapp_enabled'] == true ||
              json['whatsapp_enabled'].toString() == '1',
      whatsappMessage:
          json['whatsapp_message']?.toString() ?? 'Hello Asaan Store, ',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      playStoreUrl: json['play_store_url']?.toString() ?? '',
      appStoreUrl: json['app_store_url']?.toString() ?? '',
    );
  }

  /// The WhatsApp number with everything except digits stripped.
  ///
  /// The dashboard may store the number with spaces, dashes or a leading plus,
  /// but `wa.me` only accepts digits, so this is what the link is built from.
  String get whatsappDigits => whatsapp.replaceAll(RegExp(r'[^0-9]'), '');

  /// True only when the dashboard has WhatsApp switched on *and* there is a
  /// number to open. Every WhatsApp button in the app asks this, so one switch
  /// in the dashboard removes them all.
  bool get hasWhatsapp => whatsappEnabled && whatsappDigits.isNotEmpty;
  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasEmail => email.trim().isNotEmpty;
}
