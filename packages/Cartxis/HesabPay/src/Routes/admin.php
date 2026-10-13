<?php

use Cartxis\HesabPay\Http\Controllers\HesabPayController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| HesabPay Webhook Route
|--------------------------------------------------------------------------
|
| Public, no session, no CSRF. HesabPay signs every payload and the gateway
| verifies that signature with HesabPay before anything is written.
|
*/

Route::post('webhooks/hesabpay', [HesabPayController::class, 'webhook'])
    ->name('hesabpay.webhook');

// Configuration is handled by Settings\Http\Controllers\Admin\PaymentMethodsController
// at admin/settings/payment-methods/{type}/configure
