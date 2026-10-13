/// The customer's referral programme, as the app sees it.
///
/// Mirrors GET /api/v1/referrals. Every rule — who may be linked, the reward,
/// the unlock period — is decided by the server. The app only shows the answer,
/// so the phone and the website can never disagree.
class ReferralSummary {
  final ReferralCode referral;
  final ReferralProgramme programme;
  final ReferralBalances balances;
  final List<ReferralInvite> invited;
  final String? referredByName;

  ReferralSummary({
    required this.referral,
    required this.programme,
    required this.balances,
    required this.invited,
    this.referredByName,
  });

  factory ReferralSummary.fromJson(Map<String, dynamic> json) {
    return ReferralSummary(
      referral: ReferralCode.fromJson(
        json['referral'] as Map<String, dynamic>? ?? const {},
      ),
      programme: ReferralProgramme.fromJson(
        json['programme'] as Map<String, dynamic>? ?? const {},
      ),
      balances: ReferralBalances.fromJson(
        json['balances'] as Map<String, dynamic>? ?? const {},
      ),
      invited: (json['invited'] as List<dynamic>? ?? const [])
          .map(
              (entry) => ReferralInvite.fromJson(entry as Map<String, dynamic>))
          .toList(),
      referredByName:
          (json['referred_by'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }

  bool get hasReferredBy =>
      referredByName != null && referredByName!.trim().isNotEmpty;
}

/// The customer's own code and the message to send with it.
class ReferralCode {
  final String code;
  final String shareLink;
  final String shareText;
  final int clicks;
  final String status;

  ReferralCode({
    required this.code,
    required this.shareLink,
    required this.shareText,
    required this.clicks,
    required this.status,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      code: json['code'] as String? ?? '',
      shareLink: json['share_link'] as String? ?? '',
      shareText: json['share_text'] as String? ?? '',
      clicks: _asInt(json['clicks']),
      status: json['status'] as String? ?? 'active',
    );
  }
}

/// The rules shown to the customer, e.g. "spend this much, I earn that".
class ReferralProgramme {
  final bool enabled;
  final double rewardAmount;
  final double thresholdAmount;
  final int lockDays;
  final int creditMaxPercentOfOrder;

  ReferralProgramme({
    required this.enabled,
    required this.rewardAmount,
    required this.thresholdAmount,
    required this.lockDays,
    required this.creditMaxPercentOfOrder,
  });

  factory ReferralProgramme.fromJson(Map<String, dynamic> json) {
    return ReferralProgramme(
      enabled: json['enabled'] as bool? ?? true,
      rewardAmount: _asDouble(json['reward_amount']),
      thresholdAmount: _asDouble(json['threshold_amount']),
      lockDays: _asInt(json['lock_days']),
      creditMaxPercentOfOrder: _asInt(json['credit_max_percent_of_order']),
    );
  }
}

/// Credit the customer can spend now, credit still locked, and the totals.
class ReferralBalances {
  final double available;
  final double locked;
  final double earned;
  final double spent;

  ReferralBalances({
    required this.available,
    required this.locked,
    required this.earned,
    required this.spent,
  });

  factory ReferralBalances.fromJson(Map<String, dynamic> json) {
    return ReferralBalances(
      available: _asDouble(json['available']),
      locked: _asDouble(json['locked']),
      earned: _asDouble(json['earned']),
      spent: _asDouble(json['spent']),
    );
  }
}

/// One friend the customer invited.
class ReferralInvite {
  final int id;
  final String name;
  final double lifetimeSpend;
  final bool rewarded;
  final String status;
  final String? joinedAt;

  ReferralInvite({
    required this.id,
    required this.name,
    required this.lifetimeSpend,
    required this.rewarded,
    required this.status,
    this.joinedAt,
  });

  factory ReferralInvite.fromJson(Map<String, dynamic> json) {
    return ReferralInvite(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? 'A customer',
      lifetimeSpend: _asDouble(json['lifetime_spend']),
      rewarded: json['rewarded'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      joinedAt: json['joined_at'] as String?,
    );
  }
}

/// One line of the credit history.
class ReferralLedgerEntry {
  final int id;
  final String type;
  final double amount;
  final double? balanceAfter;
  final String? reason;
  final String? availableFrom;
  final String? createdAt;

  ReferralLedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    this.balanceAfter,
    this.reason,
    this.availableFrom,
    this.createdAt,
  });

  factory ReferralLedgerEntry.fromJson(Map<String, dynamic> json) {
    return ReferralLedgerEntry(
      id: _asInt(json['id']),
      type: json['type'] as String? ?? 'earned',
      amount: _asDouble(json['amount']),
      balanceAfter: json['balance_after'] == null
          ? null
          : _asDouble(json['balance_after']),
      reason: json['reason'] as String?,
      availableFrom: json['available_from'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  bool get isCredit => amount >= 0;

  /// Credit that is booked but not spendable yet.
  bool get isLocked {
    if (!isCredit || availableFrom == null) return false;
    final unlocksAt = DateTime.tryParse(availableFrom!);
    if (unlocksAt == null) return false;
    return unlocksAt.isAfter(DateTime.now());
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
