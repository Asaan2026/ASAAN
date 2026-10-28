<?php

namespace Cartxis\Shop\Http\Middleware;

use Cartxis\API\Helpers\ApiResponse;
use Cartxis\Core\Services\SettingService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Only a customer who has confirmed their email address may place an order.
 *
 * Browsing, searching and filling a basket are all open; this guards the one
 * step that takes money. The same rule has to hold for the website and the
 * phone app, so it lives here once rather than in each checkout controller,
 * where the two would drift apart.
 *
 * The shop owner can turn it off in Settings > Store Configuration, because a
 * shop whose customers cannot receive email would otherwise be unable to sell
 * anything at all.
 */
class RequireVerifiedCustomer
{
    public function __construct(protected SettingService $settings) {}

    public function handle(Request $request, Closure $next): Response
    {
        if (! (bool) $this->settings->get('checkout_require_verified_email', true)) {
            return $next($request);
        }

        $user = $request->user();

        // Buying needs an account, so that there is an address to confirm.
        if (! $user) {
            return $this->refuse(
                $request,
                'Please sign in to place your order.',
                'SIGN_IN_REQUIRED',
                401,
            );
        }

        if (! $user->hasVerifiedEmail()) {
            return $this->refuse(
                $request,
                'Please confirm your email address before placing an order. '
                .'We sent a link to '.$user->email.'.',
                'EMAIL_NOT_VERIFIED',
                403,
            );
        }

        return $next($request);
    }

    /**
     * The same refusal in whichever language the caller speaks: a JSON error
     * the app can act on, or a message the website shows above the form the
     * customer is standing in front of.
     */
    protected function refuse(Request $request, string $message, string $code, int $status): Response
    {
        if ($request->expectsJson() || $request->is('api/*')) {
            return ApiResponse::error($message, null, $status, $code);
        }

        return back()->withErrors(['email_verification' => $message]);
    }
}
