<?php

use Cartxis\Stripe\Http\Controllers\StripeController;
use Illuminate\Support\Facades\Route;

// Webhook route (public, no auth required)
Route::post('webhooks/stripe', [StripeController::class, 'webhook'])
    ->name('stripe.webhook');

// Note: Stripe configuration is handled by PaymentMethodsController
// at admin/settings/payment-methods/{type}/configure
