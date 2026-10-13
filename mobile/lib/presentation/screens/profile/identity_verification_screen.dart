import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vortex_app/core/constants/app_colors.dart';
import 'package:vortex_app/core/network/api_exception.dart';
import 'package:vortex_app/data/models/identity_status_model.dart';
import 'package:vortex_app/data/services/identity_service.dart';
import 'package:vortex_app/l10n/app_localizations.dart';

/// The customer's Tazkira verification, in the account area.
///
/// The website and the app share one set of rules, so the checks typed here
/// mirror the server's: same lengths, same message wording. The server still
/// checks everything again, because the app is not the guarded path.
class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nationalIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();

  final _nationalIdFocus = FocusNode();
  final _fullNameFocus = FocusNode();
  final _fatherNameFocus = FocusNode();

  final _service = IdentityService();
  final _imagePicker = ImagePicker();

  IdentityStatus? _status;
  bool _loading = true;
  String? _loadError;

  File? _image;
  DateTime? _selectedDate;
  bool _submitting = false;

  /// Errors the server sent back, shown under the field they belong to.
  Map<String, String> _serverErrors = {};
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _nationalIdFocus.dispose();
    _fullNameFocus.dispose();
    _fatherNameFocus.dispose();
    super.dispose();
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  bool get _hasUnsavedWork =>
      _isDirty &&
      (_nationalIdController.text.trim().isNotEmpty ||
          _fullNameController.text.trim().isNotEmpty ||
          _fatherNameController.text.trim().isNotEmpty ||
          _image != null);

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final status = await _service.fetchStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = e is ApiException ? e.message : _l10n.identityLoadError;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (picked != null) {
        setState(() {
          _image = File(picked.path);
          _isDirty = true;
          _serverErrors.remove('image');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_l10n.identityPhotoError} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isDirty = true;
        _serverErrors.remove('date_of_birth');
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formValid = _formKey.currentState?.validate() ?? false;
    final imageMissing = _image == null;

    setState(() {
      if (imageMissing) {
        _serverErrors['image'] = _l10n.identityPhotoMissing;
      }
    });

    if (!formValid || imageMissing) {
      return;
    }

    setState(() {
      _submitting = true;
      _serverErrors = {};
    });

    try {
      await _service.submit(
        nationalId: _nationalIdController.text,
        fullName: _fullNameController.text,
        fatherName: _fatherNameController.text,
        dateOfBirth: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        image: _image!,
      );

      if (!mounted) return;

      // Saved: the form is no longer unsaved, so a back press must not prompt.
      _isDirty = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.identitySubmitted),
          backgroundColor: Colors.green,
        ),
      );

      _nationalIdController.clear();
      _fullNameController.clear();
      _fatherNameController.clear();
      setState(() {
        _image = null;
        _selectedDate = null;
      });

      await _loadStatus();
    } catch (e) {
      if (!mounted) return;

      if (e is ApiException) {
        _applyServerErrors(e);
      } else {
        setState(() {
          _serverErrors = {'_form': _l10n.identitySubmitError};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _applyServerErrors(ApiException e) {
    final errors = <String, String>{};

    e.errors?.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        errors[key] = value.first.toString();
      } else if (value is String) {
        errors[key] = value;
      }
    });

    if (errors.isEmpty) {
      errors['_form'] = e.message;
    }

    setState(() {
      _serverErrors = errors;
    });

    // Move focus to the first problem so it scrolls into view.
    if (errors.containsKey('national_id')) {
      _nationalIdFocus.requestFocus();
    } else if (errors.containsKey('full_name')) {
      _fullNameFocus.requestFocus();
    } else if (errors.containsKey('father_name')) {
      _fatherNameFocus.requestFocus();
    }
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.identityDiscardTitle),
        content: Text(
          _l10n.identityDiscardBody,
        ),
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
      canPop: !_hasUnsavedWork,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_hasUnsavedWork) return;
        final navigator = Navigator.of(context);
        final shouldLeave = await _confirmLeave();
        if (shouldLeave) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(child: _buildBody(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF101922).withValues(alpha: 0.95)
            : const Color(0xFFF6F7F8).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              if (_hasUnsavedWork) {
                final leave = await _confirmLeave();
                if (leave && mounted) Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Text(
              _l10n.identityTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStatus,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: Text(_l10n.commonTryAgain),
              ),
            ],
          ),
        ),
      );
    }

    final status = _status!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(status, isDark),
          const SizedBox(height: 24),
          if (status.canSubmit)
            _buildForm(status, isDark)
          else if (status.verified || status.isApproved)
            _buildNotice(
              isDark,
              Icons.verified_user,
              Colors.green,
              _l10n.identityVerifiedNotice,
            )
          else
            _buildNotice(
              isDark,
              Icons.hourglass_empty,
              Colors.orange,
              _l10n.identityPendingNotice,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(IdentityStatus status, bool isDark) {
    late final Color color;
    late final IconData icon;
    late final String title;
    late final String message;

    if (status.verified || status.isApproved) {
      color = Colors.green;
      icon = Icons.verified_user;
      title = _l10n.identityVerified;
      message = status.verifiedAt != null
          ? _l10n.identityVerifiedOn(status.verifiedAt!)
          : _l10n.identityVerifiedDefault;
    } else if (status.isRejected) {
      color = Colors.red;
      icon = Icons.cancel_outlined;
      title = _l10n.identityNotAccepted;
      message = status.rejectionReason?.isNotEmpty == true
          ? status.rejectionReason!
          : _l10n.identityRejectedDefault;
    } else if (status.isPending && status.submittedAt != null) {
      color = Colors.orange;
      icon = Icons.hourglass_empty;
      title = _l10n.identityUnderReview;
      message = _l10n.identitySubmittedOn(status.submittedAt!);
    } else {
      color = AppColors.primary;
      icon = Icons.badge_outlined;
      title = _l10n.identityNotVerified;
      message = _l10n.identityNotVerifiedBody;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(
    bool isDark,
    IconData icon,
    Color color,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(IdentityStatus status, bool isDark) {
    final labelColor = isDark ? Colors.grey.shade200 : const Color(0xFF212121);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_serverErrors['_form'] != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                _serverErrors['_form']!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildLabel(_l10n.identityNumberLabel, labelColor),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nationalIdController,
            focusNode: _nationalIdFocus,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _onFieldChanged('national_id'),
            decoration: _inputDecoration(
              isDark,
              hint: _l10n.identityNumberExample,
              icon: Icons.credit_card_outlined,
              errorText: _serverErrors['national_id'],
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) {
                return _l10n.identityNumberEmpty;
              }
              if (v.length < 4 ||
                  v.length > 32 ||
                  !RegExp(r'^[A-Za-z0-9][A-Za-z0-9 \-]{2,30}[A-Za-z0-9]$')
                      .hasMatch(v)) {
                return _l10n.identityNumberInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildLabel(_l10n.identityFullNameLabel, labelColor),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameController,
            focusNode: _fullNameFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _onFieldChanged('full_name'),
            decoration: _inputDecoration(
              isDark,
              hint: _l10n.identityFullNameHint,
              icon: Icons.person_outline,
              errorText: _serverErrors['full_name'],
            ),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) {
                return _l10n.identityFullNameEmpty;
              }
              if (v.length < 3) {
                return _l10n.identityFullNameShort;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildLabel(_l10n.identityFatherNameLabel, labelColor),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fatherNameController,
            focusNode: _fatherNameFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _onFieldChanged('father_name'),
            decoration: _inputDecoration(
              isDark,
              hint: _l10n.identityFatherNameHint,
              icon: Icons.family_restroom_outlined,
              errorText: _serverErrors['father_name'],
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel(_l10n.identityDateLabel, labelColor),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 20,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                          : _l10n.identitySelectDate,
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildLabel(_l10n.identityPhotoLabel, labelColor),
          const SizedBox(height: 8),
          _buildImagePicker(isDark, status),
          const SizedBox(height: 8),
          Text(
            _l10n.identityAcceptedFormats(
              status.requirements.acceptedTypes,
              status.requirements.maxUploadLabel,
            ),
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _l10n.identitySubmit,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(bool isDark, IdentityStatus status) {
    final hasError = _serverErrors['image'] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? Colors.red
                    : (isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB)),
              ),
              image: _image != null
                  ? DecorationImage(
                      image: FileImage(_image!), fit: BoxFit.cover)
                  : null,
            ),
            child: _image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 36,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _l10n.identityPhotoTap,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Text(
            _serverErrors['image']!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
    );
  }

  InputDecoration _inputDecoration(
    bool isDark, {
    required String hint,
    required IconData icon,
    String? errorText,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(icon, size: 20),
      errorText: errorText,
      filled: true,
      fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
      border:
          border(isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      enabledBorder:
          border(isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      focusedBorder: border(AppColors.primary, 1.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _onFieldChanged(String field) {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors.remove(field));
    }
  }
}
