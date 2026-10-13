/// The signed-in customer's Tazkira verification state.
///
/// Mirrors GET /api/v1/identity. The response never carries the national ID,
/// only the status, the dates and, when a submission was refused, the
/// reviewer's reason.
class IdentityStatus {
  final bool verified;
  final String? verifiedAt;
  final String status;
  final String? submittedAt;
  final String? reviewedAt;
  final String? rejectionReason;
  final bool canSubmit;
  final bool available;
  final IdentityRequirements requirements;

  IdentityStatus({
    required this.verified,
    this.verifiedAt,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    required this.canSubmit,
    required this.available,
    required this.requirements,
  });

  factory IdentityStatus.fromJson(Map<String, dynamic> json) {
    return IdentityStatus(
      verified: json['verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] as String?,
      status: json['status'] as String? ?? 'pending',
      submittedAt: json['submitted_at'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      canSubmit: json['can_submit'] as bool? ?? false,
      available: json['available'] as bool? ?? true,
      requirements: IdentityRequirements.fromJson(
        json['requirements'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  bool get isApproved => verified || status == 'approved';

  bool get isPending => !verified && status == 'pending';

  bool get isRejected => status == 'rejected';

  /// A submission exists but the reviewer has not decided yet.
  bool get hasPendingSubmission => isPending && submittedAt != null;
}

/// The upload rules shown to the customer before they pick a photo.
class IdentityRequirements {
  final int maxUploadKb;
  final String acceptedTypes;
  final String requiredDocument;

  IdentityRequirements({
    required this.maxUploadKb,
    required this.acceptedTypes,
    required this.requiredDocument,
  });

  factory IdentityRequirements.fromJson(Map<String, dynamic> json) {
    return IdentityRequirements(
      maxUploadKb: json['max_upload_kb'] as int? ?? 4096,
      acceptedTypes: json['accepted_types'] as String? ?? 'JPG, PNG, WebP',
      requiredDocument: json['required_document'] as String? ?? 'Tazkira',
    );
  }

  String get maxUploadLabel {
    if (maxUploadKb >= 1024) {
      final mb = maxUploadKb / 1024;
      final label = mb == mb.roundToDouble()
          ? mb.toStringAsFixed(0)
          : mb.toStringAsFixed(1);
      return '$label MB';
    }
    return '$maxUploadKb KB';
  }
}
