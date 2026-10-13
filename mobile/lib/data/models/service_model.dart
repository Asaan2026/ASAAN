/// The shop's services (bookable jobs), as the app sees them.
///
/// Mirrors `/api/v1/services*`. A service is not a product: it is never added
/// to a basket and never shipped, so it carries a fixed price, a duration and a
/// coverage area instead of stock or variants.
class ServiceItem {
  final int id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final List<String> includes;
  final List<String> excludes;
  final String? icon;
  final bool iconOnly;
  final String? imageUrl;
  final String priceText;
  final String priceUnit;
  final String? priceNote;
  final int durationMinutes;
  final String? durationDisplay;
  final String? serviceArea;
  final bool featured;
  final bool bookingEnabled;
  final ServiceCategory? category;

  ServiceItem({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    this.includes = const [],
    this.excludes = const [],
    this.icon,
    this.iconOnly = false,
    this.imageUrl,
    required this.priceText,
    required this.priceUnit,
    this.priceNote,
    this.durationMinutes = 0,
    this.durationDisplay,
    this.serviceArea,
    this.featured = false,
    this.bookingEnabled = false,
    this.category,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      includes: _asStringList(json['includes']),
      excludes: _asStringList(json['excludes']),
      icon: json['icon'] as String?,
      iconOnly: json['icon_only'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      priceText: json['price_display'] as String? ?? '',
      priceUnit: json['price_unit'] as String? ?? 'per_job',
      priceNote: json['price_note'] as String?,
      durationMinutes: _asInt(json['duration_minutes']),
      durationDisplay: json['duration_display'] as String?,
      serviceArea: json['service_area'] as String?,
      featured: json['featured'] as bool? ?? false,
      bookingEnabled: json['booking_enabled'] as bool? ?? false,
      category: json['category'] == null
          ? null
          : ServiceCategory.fromJson(json['category'] as Map<String, dynamic>),
    );
  }
}

/// One browsable group of services.
class ServiceCategory {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String? image;
  final int servicesCount;
  final int sortOrder;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.image,
    this.servicesCount = 0,
    this.sortOrder = 0,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      image: json['image'] as String?,
      servicesCount: _asInt(json['services_count']),
      sortOrder: _asInt(json['sort_order']),
    );
  }
}

/// One service with everything the app needs before offering a booking.
class ServiceDetail {
  final ServiceItem service;
  final List<ServiceItem> related;
  final ServiceBookingWindow booking;
  final ServicePublicSettings settings;

  ServiceDetail({
    required this.service,
    required this.related,
    required this.booking,
    required this.settings,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    return ServiceDetail(
      service: ServiceItem.fromJson(
        json['service'] as Map<String, dynamic>? ?? const {},
      ),
      related: (json['related'] as List<dynamic>? ?? const [])
          .map((item) => ServiceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      booking: ServiceBookingWindow.fromJson(
        json['booking'] as Map<String, dynamic>? ?? const {},
      ),
      settings: ServicePublicSettings.fromJson(
        json['settings'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// When a service can be booked, and which times of day are offered.
class ServiceBookingWindow {
  final bool enabled;
  final bool requiresLogin;
  final List<String> slots;
  final String? earliestDate;
  final String? latestDate;

  ServiceBookingWindow({
    required this.enabled,
    required this.requiresLogin,
    required this.slots,
    this.earliestDate,
    this.latestDate,
  });

  factory ServiceBookingWindow.fromJson(Map<String, dynamic> json) {
    return ServiceBookingWindow(
      enabled: json['enabled'] as bool? ?? false,
      requiresLogin: json['requires_login'] as bool? ?? false,
      slots: _asStringList(json['slots']),
      earliestDate: json['earliest_date'] as String?,
      latestDate: json['latest_date'] as String?,
    );
  }
}

/// The slice of service settings a customer is allowed to see.
class ServicePublicSettings {
  final String? coverageNote;
  final String? contactPhone;
  final String? contactWhatsapp;

  ServicePublicSettings({
    this.coverageNote,
    this.contactPhone,
    this.contactWhatsapp,
  });

  factory ServicePublicSettings.fromJson(Map<String, dynamic> json) {
    return ServicePublicSettings(
      coverageNote: json['coverage_note'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactWhatsapp: json['contact_whatsapp'] as String?,
    );
  }
}

/// The booking window for the date picker.
class ServiceSlots {
  final List<String> slots;
  final String? earliestDate;
  final String? latestDate;

  ServiceSlots({
    required this.slots,
    this.earliestDate,
    this.latestDate,
  });

  factory ServiceSlots.fromJson(Map<String, dynamic> json) {
    return ServiceSlots(
      slots: _asStringList(json['slots']),
      earliestDate: json['earliest_date'] as String?,
      latestDate: json['latest_date'] as String?,
    );
  }
}

/// The receipt the customer gets back after booking.
class ServiceBookingResult {
  final String reference;
  final String status;
  final String? scheduledDate;
  final String? scheduledSlot;
  final String? serviceName;
  final String? priceText;
  final String? priceUnit;
  final String? customerPhone;

  ServiceBookingResult({
    required this.reference,
    required this.status,
    this.scheduledDate,
    this.scheduledSlot,
    this.serviceName,
    this.priceText,
    this.priceUnit,
    this.customerPhone,
  });

  factory ServiceBookingResult.fromJson(Map<String, dynamic> json) {
    return ServiceBookingResult(
      reference: json['reference'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      scheduledDate: json['scheduled_date'] as String?,
      scheduledSlot: json['scheduled_slot'] as String?,
      serviceName: json['service_name'] as String?,
      priceText: json['price']?.toString(),
      priceUnit: json['price_unit'] as String?,
      customerPhone: json['customer_phone'] as String?,
    );
  }
}

/// One page of the services list, with enough to ask for the next.
class ServiceCatalogPage {
  final List<ServiceItem> items;
  final int currentPage;
  final int lastPage;

  ServiceCatalogPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  return const [];
}
