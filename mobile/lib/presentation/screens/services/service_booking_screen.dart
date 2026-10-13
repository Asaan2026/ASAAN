import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/service_catalog_service.dart';
import '../../../l10n/app_localizations.dart';

/// The form that turns a chosen service into a real, scheduled job.
///
/// The rules here are the same ones the website and the server use: the same
/// fields, the same wording, the same checks. The server is still the judge —
/// this side only catches mistakes before a wasted trip.
class ServiceBookingScreen extends StatefulWidget {
  const ServiceBookingScreen({
    super.key,
    required this.slug,
    required this.serviceName,
  });

  final String slug;
  final String serviceName;

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final ServiceCatalogService _service = ServiceCatalogService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  final String _requestToken = 'svc-${DateTime.now().microsecondsSinceEpoch}';

  ServiceSlots? _slots;
  ServiceBookingResult? _booking;
  String? _date;
  String? _slot;
  String? _error;
  bool _submitting = false;
  Map<String, String> _serverErrors = {};

  AppLocalizations get _l10n => AppLocalizations.of(context);

  /// True while the form holds work the customer would hate to lose, and has
  /// not yet been sent.
  bool get _hasUnsaved {
    if (_booking != null) return false;
    return _name.text.trim().isNotEmpty ||
        _phone.text.trim().isNotEmpty ||
        _email.text.trim().isNotEmpty ||
        _address.text.trim().isNotEmpty ||
        _city.text.trim().isNotEmpty ||
        _notes.text.trim().isNotEmpty ||
        _date != null ||
        _slot != null;
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _phone, _email, _address, _city, _notes]) {
      controller.addListener(_onFieldChanged);
    }
    _loadSlots();
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _email, _address, _city, _notes]) {
      controller.removeListener(_onFieldChanged);
      controller.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    // Keep the back-guard honest without rebuilding the whole page on a key.
    if (mounted) setState(() {});
  }

  Future<void> _loadSlots() async {
    setState(() {
      _slots = null;
      _error = null;
    });

    try {
      final slots = await _service.fetchSlots(widget.slug);
      if (!mounted) return;
      setState(() => _slots = slots);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = _l10n.bookingCalendarError);
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime _clamp(DateTime value, DateTime first, DateTime last) {
    if (value.isBefore(first)) return first;
    if (value.isAfter(last)) return last;
    return value;
  }

  Future<void> _pickDate() async {
    final first = _parseDate(_slots?.earliestDate) ?? DateTime.now();
    final last = _parseDate(_slots?.latestDate) ??
        DateTime.now().add(const Duration(days: 60));
    final initial = _parseDate(_date) ?? first;

    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(initial, first, last),
      firstDate: first,
      lastDate: last,
    );

    if (picked == null) return;
    setState(() {
      _date = DateFormat('yyyy-MM-dd').format(picked);
      _serverErrors.remove('scheduled_date');
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _serverErrors = {};
    });

    try {
      final result = await _service.book(widget.slug, {
        'customer_name': _name.text.trim(),
        'customer_phone': _phone.text.trim(),
        if (_email.text.trim().isNotEmpty) 'customer_email': _email.text.trim(),
        'address': _address.text.trim(),
        if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        'scheduled_date': _date,
        'scheduled_slot': _slot,
        'request_token': _requestToken,
      });

      if (!mounted) return;
      setState(() {
        _booking = result;
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final mapped = _normaliseErrors(e.errors);
      setState(() {
        _serverErrors = mapped;
        _submitting = false;
      });
      if (mapped.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      } else {
        _formKey.currentState?.validate();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_l10n.bookingSendFailed),
        ),
      );
    }
  }

  Map<String, String> _normaliseErrors(Map<String, dynamic>? errors) {
    if (errors == null) return {};
    final result = <String, String>{};
    errors.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        result[key] = value.first.toString();
      } else if (value != null) {
        result[key] = value.toString();
      }
    });
    return result;
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.bookingDiscardTitle),
        content: Text(_l10n.bookingDiscardBody),
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
      canPop: !_hasUnsaved,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasUnsaved) return;
        final navigator = Navigator.of(context);
        final shouldLeave = await _confirmLeave();
        if (shouldLeave) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: Text(_l10n.bookingTitle),
          backgroundColor: background,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
        ),
        body: SafeArea(child: _buildBody(isDark)),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_booking != null) {
      return _buildSuccess(_booking!, isDark);
    }

    if (_slots == null) {
      if (_error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  onPressed: _loadSlots,
                  child: Text(_l10n.commonTryAgain),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.serviceName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _l10n.bookingIntro,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          _textField(
            controller: _name,
            label: _l10n.bookingName,
            isRequired: true,
            serverKey: 'customer_name',
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return _l10n.bookingNameRequired;
              }
              return null;
            },
          ),
          _textField(
            controller: _phone,
            label: _l10n.bookingPhone,
            isRequired: true,
            keyboardType: TextInputType.phone,
            serverKey: 'customer_phone',
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) {
                return _l10n.bookingPhoneRequired;
              }
              if (text.length < 6) return _l10n.bookingPhoneShort;
              return null;
            },
          ),
          _textField(
            controller: _email,
            label: _l10n.bookingEmail,
            keyboardType: TextInputType.emailAddress,
            serverKey: 'customer_email',
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return null;
              if (!text.contains('@') || !text.contains('.')) {
                return _l10n.bookingEmailInvalid;
              }
              return null;
            },
          ),
          _textField(
            controller: _address,
            label: _l10n.bookingAddress,
            isRequired: true,
            maxLines: 2,
            serverKey: 'address',
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) {
                return _l10n.bookingAddressRequired;
              }
              if (text.length < 10) {
                return _l10n.bookingAddressShort;
              }
              return null;
            },
          ),
          _textField(
            controller: _city,
            label: _l10n.bookingCity,
            serverKey: 'city',
          ),
          const SizedBox(height: 8),
          _buildDateField(isDark),
          const SizedBox(height: 16),
          _buildSlotField(isDark),
          const SizedBox(height: 16),
          _textField(
            controller: _notes,
            label: _l10n.bookingNotes,
            maxLines: 3,
            serverKey: 'notes',
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_l10n.bookingSend),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? serverKey,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_submitting,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) {
          if (serverKey != null) {
            final serverError = _serverErrors[serverKey];
            if (serverError != null) return serverError;
          }
          return validator?.call(value);
        },
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return FormField<String>(
      initialValue: _date,
      validator: (_) {
        final serverError = _serverErrors['scheduled_date'];
        if (serverError != null) {
          return serverError;
        }
        if (_date == null) {
          return _l10n.bookingDateRequired;
        }
        return null;
      },
      builder: (state) {
        final label = _date == null
            ? _l10n.bookingPickDate
            : DateFormat.yMMMMd().format(DateTime.parse(_date!));

        return InkWell(
          onTap: _submitting ? null : _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '${_l10n.bookingDate} *',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.calendar_today, size: 18),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: _date == null
                    ? (isDark ? Colors.white54 : Colors.black45)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotField(bool isDark) {
    final slots = _slots?.slots ?? const [];

    return FormField<String>(
      initialValue: _slot,
      validator: (value) {
        final serverError = _serverErrors['scheduled_slot'];
        if (serverError != null) return serverError;
        if (value == null || value.isEmpty) {
          return _l10n.bookingTimeRequired;
        }
        return null;
      },
      builder: (state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: '${_l10n.bookingTime} *',
            border: const OutlineInputBorder(),
            isDense: true,
            errorText: state.errorText,
          ),
          child: DropdownButton<String>(
            value: _slot,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: Text(
              _l10n.bookingPickTime,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            items: slots
                .map(
                  (slot) => DropdownMenuItem<String>(
                    value: slot,
                    child: Text(slot),
                  ),
                )
                .toList(),
            onChanged: _submitting
                ? null
                : (value) {
                    setState(() {
                      _slot = value;
                      _serverErrors.remove('scheduled_slot');
                    });
                    state.didChange(value);
                  },
          ),
        );
      },
    );
  }

  Widget _buildSuccess(ServiceBookingResult booking, bool isDark) {
    final scheduled = _parseDate(booking.scheduledDate);
    final date = scheduled == null ? '' : DateFormat.yMMMMd().format(scheduled);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Center(
          child: Icon(Icons.check_circle, size: 64, color: Color(0xFF00A651)),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _l10n.bookingSentTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _l10n.bookingSentBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2733) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(_l10n.bookingReference, booking.reference, isDark),
              if ((booking.serviceName ?? '').isNotEmpty)
                _row(_l10n.bookingServiceLabel, booking.serviceName!, isDark),
              if (date.isNotEmpty) _row(_l10n.bookingDate, date, isDark),
              if ((booking.scheduledSlot ?? '').isNotEmpty)
                _row(_l10n.bookingTime, booking.scheduledSlot!, isDark),
              if ((booking.customerPhone ?? '').isNotEmpty)
                _row(_l10n.bookingPhoneLabel, booking.customerPhone!, isDark),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_l10n.commonDone),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
