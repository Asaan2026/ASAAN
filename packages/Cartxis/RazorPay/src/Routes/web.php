<?php

use Cartxis\Razorpay\Http\Controllers\RazorpayController;
use Illuminate\Support\Facades\Route;

// Razorpay payment routes
Route::middleware(['web'])->group(function () {
    // Payment callback (from Razorpay Checkout)
    Route::get('razorpay/callback/{order}', [RazorpayController::class, 'paymentCallback'])
        ->name('razorpay.callback');

    // Payment cancel callback
    Route::get('razorpay/cancel/{order}', [RazorpayController::class, 'paymentCancel'])
        ->name('razorpay.cancel');
});
