import 'package:flutter/material.dart';
import 'package:vortex_app/core/network/api_exception.dart';
import 'package:vortex_app/data/services/order_service.dart';
import 'package:vortex_app/data/services/review_service.dart';
import 'package:vortex_app/l10n/app_localizations.dart';

/// Lets a customer review something they bought.
///
/// The button for this used to say "Leave Review coming soon". The server has
/// accepted reviews all along; only the screen was missing.
///
/// An order can hold several products, so the customer picks which one they
/// are reviewing. The shop reads reviews before publishing them, so the
/// confirmation says the review is waiting rather than pretending it is live.
class LeaveReviewSheet extends StatefulWidget {
  const LeaveReviewSheet({super.key, required this.order});

  final Order order;

  /// Opens the sheet. Returns true when a review was sent.
  static Future<bool> show(BuildContext context, Order order) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: LeaveReviewSheet(order: order),
      ),
    );

    return sent ?? false;
  }

  @override
  State<LeaveReviewSheet> createState() => _LeaveReviewSheetState();
}

class _LeaveReviewSheetState extends State<LeaveReviewSheet> {
  final ReviewService _reviews = ReviewService();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();

  OrderItem? _item;
  int _rating = 5;
  bool _sending = false;
  String? _error;
  String? _titleError;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    final reviewable = _reviewableItems;
    _item = reviewable.isEmpty ? null : reviewable.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// Only lines whose product still exists can be reviewed.
  List<OrderItem> get _reviewableItems =>
      widget.order.items.where((i) => (i.productId ?? 0) > 0).toList();

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final item = _item;

    // Both fields checked at once, each message under its own field.
    setState(() {
      _titleError =
          _titleController.text.trim().isEmpty ? l10n.reviewTitleRequired : null;
      _commentError = _commentController.text.trim().isEmpty
          ? l10n.reviewCommentRequired
          : null;
      _error = null;
    });

    if (item == null || _titleError != null || _commentError != null) return;

    setState(() => _sending = true);

    try {
      await _reviews.submit(
        productId: item.productId!,
        rating: _rating,
        title: _titleController.text.trim(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // The shop's own reason: already reviewed, or not bought by this
      // customer. Both are more useful than anything invented here.
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = AppLocalizations.of(context).guardCouldNotReachShop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _reviewableItems;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reviewTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.reviewAwaitsApproval,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            if (items.isEmpty)
              Text(l10n.reviewNothingToReview)
            else ...[
              // Which product, when the order held more than one.
              if (items.length > 1)
                DropdownButtonFormField<OrderItem>(
                  initialValue: _item,
                  decoration: InputDecoration(
                    labelText: l10n.reviewWhichProduct,
                    border: const OutlineInputBorder(),
                  ),
                  items: items
                      .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text(
                              i.productName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _item = value),
                )
              else
                Text(
                  items.first.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

              const SizedBox(height: 16),
              Text(l10n.reviewYourRating),
              Row(
                children: List.generate(5, (index) {
                  final star = index + 1;

                  return IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                  );
                }),
              ),

              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.reviewHeadline,
                  border: const OutlineInputBorder(),
                  errorText: _titleError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: l10n.reviewComment,
                  border: const OutlineInputBorder(),
                  errorText: _commentError,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.reviewSend),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
