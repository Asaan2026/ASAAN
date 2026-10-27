import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_app/core/network/api_exception.dart';
import 'package:vortex_app/l10n/app_localizations.dart';

/// The one place that decides whether a customer may put something in their
/// basket or save it for later, and what to say when they may not.
///
/// Anyone can browse the shop without an account. Keeping a basket or a saved
/// list needs one, because both belong to a person — the server requires it
/// too. Before this existed, a signed-out customer tapping "Add to Cart" was
/// told "Failed to add to cart", which reads like a broken shop rather than an
/// invitation to sign in.
///
/// Every button that needs an account goes through [run], so the wording and
/// the way out are the same wherever the customer meets it.
class ShoppingGuard {
  const ShoppingGuard._();

  /// Judged by the stored token rather than the separate "isLoggedIn" flag,
  /// which has been seen missing on a restored session.
  static Future<bool> isSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Carry out [action] when the customer may, and explain when they may not.
  ///
  /// Returns true only when the action actually went through, so the caller
  /// can decide whether to show its own confirmation or refresh a badge.
  ///
  /// [reason] completes the sentence "Sign in to ..." — for example
  /// "add this to your basket".
  static Future<bool> run(
    BuildContext context, {
    required String reason,
    required Future<void> Function() action,
  }) async {
    if (!await isSignedIn()) {
      if (!context.mounted) return false;
      await _askToSignIn(context, reason);

      return false;
    }

    try {
      await action();

      return true;
    } on ApiException catch (e) {
      if (!context.mounted) return false;

      // The token has expired or been revoked: same situation as never having
      // signed in, so offer the same way out rather than an error.
      if (e.statusCode == 401 || e.code == 'UNAUTHORIZED') {
        await _askToSignIn(context, reason);

        return false;
      }

      // The shop's own words — "Insufficient stock", "Product not available" —
      // are more use than anything this app could invent.
      _say(context, e.message);

      return false;
    } catch (_) {
      if (!context.mounted) return false;
      _say(context, AppLocalizations.of(context).guardCouldNotReachShop);

      return false;
    }
  }

  static Future<void> _askToSignIn(BuildContext context, String reason) async {
    final l10n = AppLocalizations.of(context);

    final goToSignIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.guardSignInTitle),
        content: Text(l10n.guardSignInBody(reason)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.guardNotNow),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.guardSignIn),
          ),
        ],
      ),
    );

    if (goToSignIn != true || !context.mounted) return;

    // The app's own navigator: these buttons sit inside tabs that keep a
    // navigator of their own, which would otherwise swallow the route.
    await Navigator.of(context, rootNavigator: true).pushNamed('/login');
  }

  static void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
