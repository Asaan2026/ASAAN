import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../data/models/referral_model.dart';
import '../../../data/services/referral_service.dart';
import '../../../l10n/app_localizations.dart';

/// The customer's referral page in the app.
///
/// The same programme the website runs: one code to share, a credit balance,
/// the friends who joined, and the history of every credit change. The rules
/// are the server's, so this screen never computes a reward itself.
class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  final ReferralService _service = ReferralService();
  final TextEditingController _codeController = TextEditingController();

  ReferralSummary? _summary;
  List<ReferralLedgerEntry> _ledger = const [];
  bool _loading = true;
  bool _applying = false;
  String? _error;
  String? _applyError;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool get _hasUnsavedCode => _codeController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    _load();
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    // Keep the back-guard honest without rebuilding the whole page on a keystroke.
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.fetchSummary(),
        _service.fetchLedger(),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as ReferralSummary;
        _ledger = results[1] as List<ReferralLedgerEntry>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _l10n.commonError;
        _loading = false;
      });
    }
  }

  Future<void> _applyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _applyError = _l10n.referralApplyEmpty);
      return;
    }

    setState(() {
      _applying = true;
      _applyError = null;
    });

    try {
      await _service.applyCode(code);
      if (!mounted) return;
      _codeController.clear();
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.referralApplied)),
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _applyError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _applyError = _l10n.referralApplyFailed;
      });
    }
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.referralDiscardTitle),
        content: Text(_l10n.referralDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_l10n.commonKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_l10n.commonDiscard),
          ),
        ],
      ),
    );

    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF101922) : const Color(0xFFF6F7F8);

    return PopScope(
      canPop: !_hasUnsavedCode,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasUnsavedCode) return;
        final navigator = Navigator.of(context);
        final shouldLeave = await _confirmLeave();
        if (shouldLeave) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(_l10n.referralsTitle),
          backgroundColor: background,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _buildBody(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: _load, child: Text(_l10n.commonTryAgain)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final summary = _summary!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (!summary.programme.enabled) ...[
          _buildNote(
            isDark,
            _l10n.referralProgramOff,
          ),
          const SizedBox(height: 16),
        ],
        _buildBalanceCard(summary, isDark),
        const SizedBox(height: 16),
        _buildShareCard(summary, isDark),
        const SizedBox(height: 16),
        _buildApplyCard(summary, isDark),
        const SizedBox(height: 16),
        _buildInvitedCard(summary, isDark),
        const SizedBox(height: 16),
        _buildHistoryCard(isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBalanceCard(ReferralSummary summary, bool isDark) {
    final balances = summary.balances;

    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.referralCreditAvailable,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.formatSync(balances.available),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat(_l10n.referralPending, balances.locked, isDark),
              _buildStat(_l10n.referralEarned, balances.earned, isDark),
              _buildStat(_l10n.referralUsed, balances.spent, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, double amount, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyUtils.formatSync(amount),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(ReferralSummary summary, bool isDark) {
    final referral = summary.referral;
    final programme = summary.programme;

    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.referralYourCode,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2733) : const Color(0xFFEFF3F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              referral.code.isEmpty ? '—' : referral.code,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _l10n.referralShareBody(
              CurrencyUtils.formatSync(programme.thresholdAmount),
              CurrencyUtils.formatSync(programme.rewardAmount),
              programme.lockDays,
            ),
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: referral.code.isEmpty
                      ? null
                      : () => _copy(referral.code, _l10n.referralCopiedCode),
                  icon: const Icon(Icons.tag, size: 18),
                  label: Text(_l10n.referralCopyCode),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: referral.shareLink.isEmpty
                      ? null
                      : () => _copy(
                            referral.shareText.isNotEmpty
                                ? referral.shareText
                                : referral.shareLink,
                            _l10n.referralCopiedLink,
                          ),
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(_l10n.commonShare),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplyCard(ReferralSummary summary, bool isDark) {
    if (summary.hasReferredBy) {
      return _buildNote(
        isDark,
        _l10n.referralJoinedWith(summary.referredByName ?? ''),
      );
    }

    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.referralHaveCode,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _l10n.referralApplyHint,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            enabled: !_applying,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: _l10n.referralApplyFieldHint,
              errorText: _applyError,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _applying ? null : _applyCode,
              child: _applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_l10n.referralApplyButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitedCard(ReferralSummary summary, bool isDark) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.referralInvitedTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (summary.invited.isEmpty)
            Text(
              _l10n.referralInvitedEmpty,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            )
          else
            ...summary.invited
                .map((invite) => _buildInviteRow(invite, summary, isDark)),
        ],
      ),
    );
  }

  Widget _buildInviteRow(
    ReferralInvite invite,
    ReferralSummary summary,
    bool isDark,
  ) {
    final threshold = summary.programme.thresholdAmount;
    final joined = _formatDate(invite.joinedAt);

    final status = invite.rewarded
        ? _l10n.referralRewarded
        : invite.status != 'active'
            ? _l10n.referralVoided
            : invite.lifetimeSpend >= threshold
                ? _l10n.referralRewardPending
                : _l10n.referralSpentSoFar(
                    CurrencyUtils.formatSync(invite.lifetimeSpend));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            invite.rewarded ? Icons.check_circle : Icons.person_outline,
            size: 20,
            color: invite.rewarded
                ? Colors.green
                : (isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  joined.isEmpty
                      ? status
                      : '$status · ${_l10n.referralJoined(joined)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(bool isDark) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.referralHistoryTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (_ledger.isEmpty)
            Text(
              _l10n.referralHistoryEmpty,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            )
          else
            ..._ledger.map((entry) => _buildLedgerRow(entry, isDark)),
        ],
      ),
    );
  }

  Widget _buildLedgerRow(ReferralLedgerEntry entry, bool isDark) {
    final amountColor = entry.isCredit
        ? Colors.green
        : (isDark ? const Color(0xFFFF6B6B) : Colors.red.shade600);
    final amountText =
        '${entry.isCredit ? '+' : '-'}${CurrencyUtils.formatSync(entry.amount.abs())}';
    final date = _formatDate(entry.createdAt);
    final subtitleParts = <String>[
      if (date.isNotEmpty) date,
      if (entry.reason != null && entry.reason!.trim().isNotEmpty)
        entry.reason!.trim(),
      if (entry.isLocked)
        _l10n.referralLockedUntil(_formatDate(entry.availableFrom)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ledgerTypeLabel(entry.type),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNote(bool isDark, String message) {
    return _card(
      isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18222C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF243040) : const Color(0xFFE6E9EC),
        ),
      ),
      child: child,
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '';
    return DateFormat.yMMMd().format(parsed.toLocal());
  }

  String _ledgerTypeLabel(String type) {
    switch (type) {
      case 'earned':
        return _l10n.referralLedgerReward;
      case 'spent':
        return _l10n.referralLedgerSpent;
      case 'reversed':
        return _l10n.referralLedgerReversed;
      case 'admin_credit':
        return _l10n.referralLedgerAdminCredit;
      case 'admin_debit':
        return _l10n.referralLedgerAdminDebit;
      default:
        return _l10n.referralLedgerCredit;
    }
  }
}
