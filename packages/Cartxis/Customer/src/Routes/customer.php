<?php

use Cartxis\Customer\Http\Controllers\CustomerAddressController;
use Cartxis\Customer\Http\Controllers\CustomerController;
use Cartxis\Customer\Http\Controllers\CustomerGroupController;
use Illuminate\Support\Facades\Route;

Route::middleware(['web', 'auth:admin'])->prefix('admin')->name('admin.')->group(function () {
    // Customer Groups (must be defined BEFORE customers resource to avoid route conflicts)
    Route::prefix('customers')->name('customers.')->group(function () {
        Route::resource('groups', CustomerGroupController::class);

        // Customer group reordering
        Route::post('groups/reorder', [CustomerGroupController::class, 'reorder'])
            ->name('groups.reorder');

        // Customer group auto-assignment
        Route::post('groups/{group}/apply-auto-assignment', [CustomerGroupController::class, 'applyAutoAssignment'])
            ->name('groups.apply-auto-assignment');

        // Customer group bulk actions
        Route::post('groups/bulk-delete', [CustomerGroupController::class, 'bulkDestroy'])
            ->name('groups.bulk-delete');
        Route::post('groups/bulk-update-status', [CustomerGroupController::class, 'bulkUpdateStatus'])
            ->name('groups.bulk-update-status');
    });

    // Customer bulk actions (must be before resource routes)
    Route::post('customers/bulk-update-status', [CustomerController::class, 'bulkUpdateStatus'])
        ->name('customers.bulk-update-status');
    Route::post('customers/bulk-delete', [CustomerController::class, 'bulkDelete'])
        ->name('customers.bulk-delete');

    // Customer export (must be before resource routes)
    Route::get('customers/export/csv', [CustomerController::class, 'export'])
        ->name('customers.export');

    // Customer addresses (child resource under a customer)
    Route::prefix('customers/{customer}/addresses')->name('customers.addresses.')->where(['customer' => '[0-9]+'])->group(function () {
        Route::get('/', [CustomerAddressController::class, 'index'])->name('index');
        Route::get('/create', [CustomerAddressController::class, 'create'])->name('create');
        Route::post('/', [CustomerAddressController::class, 'store'])->name('store');
        Route::get('/{address}/edit', [CustomerAddressController::class, 'edit'])->name('edit');
        Route::put('/{address}', [CustomerAddressController::class, 'update'])->name('update');
        Route::delete('/{address}', [CustomerAddressController::class, 'destroy'])->name('destroy');

        Route::post('/{address}/set-default-shipping', [CustomerAddressController::class, 'setDefaultShipping'])
            ->name('set-default-shipping');
        Route::post('/{address}/set-default-billing', [CustomerAddressController::class, 'setDefaultBilling'])
            ->name('set-default-billing');
    });

    // Customers resource (should be LAST to avoid catching specific routes)
    // Constrained to numeric ids so a sibling like /admin/customers/identity is
    // not swallowed by {customer}. Without this, Postgres is asked to compare an
    // integer id to the word "identity", which is a database error (500), not a
    // missing record (404).
    Route::resource('customers', CustomerController::class)->where(['customer' => '[0-9]+']);
});
