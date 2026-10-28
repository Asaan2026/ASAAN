<?php

use Cartxis\Referral\Http\Controllers\ReferralDashboardController;
use Cartxis\Shop\Http\Controllers\Account\AddressController;
use Cartxis\Shop\Http\Controllers\Account\DashboardController;
use Cartxis\Shop\Http\Controllers\Account\NotificationController;
use Cartxis\Shop\Http\Controllers\Account\OrderController;
use Cartxis\Shop\Http\Controllers\Account\ProfileController;
use Cartxis\Shop\Http\Controllers\Account\WishlistController;
use Cartxis\Shop\Http\Controllers\CategoryController;
use Cartxis\Shop\Http\Controllers\Checkout\CheckoutController;
use Cartxis\Shop\Http\Controllers\HomeController;
use Cartxis\Shop\Http\Controllers\NewsletterController;
use Cartxis\Shop\Http\Controllers\ProductController;
use Cartxis\Shop\Http\Controllers\SearchController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Shop Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register all shop routes for the storefront.
| These routes are loaded by the ShopServiceProvider within a group which
| contains the "web" middleware group.
|
*/

Route::group([
    'middleware' => config('shop.routes.middleware', ['web']),
    'prefix' => config('shop.routes.prefix', ''),
], function () {

    /*
    |--------------------------------------------------------------------------
    | Homepage
    |--------------------------------------------------------------------------
    */
    Route::get('/', [HomeController::class, 'index'])->name('shop.home');

    /*
    |--------------------------------------------------------------------------
    | Product Routes
    |--------------------------------------------------------------------------
    */
    Route::get('/products', [ProductController::class, 'index'])->name('shop.products.index');
    Route::get('/products/{slug}/quick-view', [ProductController::class, 'quickView'])->name('shop.products.quick-view');
    Route::get('/product/{slug}', [ProductController::class, 'show'])->name('shop.products.show');

    /*
    |--------------------------------------------------------------------------
    | Category Routes
    |--------------------------------------------------------------------------
    */
    Route::get('/category/{slug}', [CategoryController::class, 'show'])->name('shop.categories.show');

    /*
    |--------------------------------------------------------------------------
    | Search Routes
    |--------------------------------------------------------------------------
    */
    Route::get('/search', [SearchController::class, 'index'])->name('shop.search');
    Route::get('/search/suggestions', [SearchController::class, 'suggestions'])->name('shop.search.suggestions');

    /*
    |--------------------------------------------------------------------------
    | Newsletter Routes
    |--------------------------------------------------------------------------
    */
    Route::post('/newsletter/subscribe', [NewsletterController::class, 'subscribe'])->name('shop.newsletter.subscribe');
    Route::post('/newsletter/unsubscribe', [NewsletterController::class, 'unsubscribe'])->name('shop.newsletter.unsubscribe');

    /*
    |--------------------------------------------------------------------------
    | Customer Account Routes
    |--------------------------------------------------------------------------
    */
    Route::group([
        'prefix' => 'account',
        'middleware' => ['auth'],
        'as' => 'shop.account.',
    ], function () {
        Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
        Route::get('/orders', [OrderController::class, 'index'])->name('orders.index');
        Route::get('/orders/{order}', [OrderController::class, 'show'])->name('orders.show');
        Route::get('/addresses', [AddressController::class, 'index'])->name('addresses.index');
        Route::post('/addresses', [AddressController::class, 'store'])->name('addresses.store');
        Route::put('/addresses/{address}', [AddressController::class, 'update'])->name('addresses.update');
        Route::delete('/addresses/{address}', [AddressController::class, 'destroy'])->name('addresses.destroy');
        Route::post('/addresses/{address}/default-shipping', [AddressController::class, 'setDefaultShipping'])->name('addresses.default-shipping');
        Route::post('/addresses/{address}/default-billing', [AddressController::class, 'setDefaultBilling'])->name('addresses.default-billing');
        /*
        |----------------------------------------------------------------------
        | Notifications
        |----------------------------------------------------------------------
        |
        | The website's own bell and page. These are session-auth routes, NOT the
        | token-only API routes -- the storefront logs in with a session, so it
        | cannot use `auth:sanctum`.
        |
        */
        Route::prefix('notifications')->name('notifications.')->group(function () {
            Route::get('/', [NotificationController::class, 'index'])->name('index');
            Route::get('/feed', [NotificationController::class, 'feed'])->name('feed');
            Route::get('/unread-count', [NotificationController::class, 'unreadCount'])->name('unread-count');
            Route::post('/read-all', [NotificationController::class, 'markAllRead'])->name('read-all');
            Route::post('/{id}/read', [NotificationController::class, 'markRead'])->name('mark-read')->whereNumber('id');
        });

        Route::get('/wishlist', [WishlistController::class, 'index'])->name('wishlist.index');
        Route::get('/wishlist/get', [WishlistController::class, 'get'])->name('wishlist.get');
        Route::post('/wishlist/add', [WishlistController::class, 'add'])->name('wishlist.add');
        Route::delete('/wishlist/item/{id}', [WishlistController::class, 'remove'])->name('wishlist.remove');
        Route::post('/wishlist/item/{id}/move-to-cart', [WishlistController::class, 'moveToCart'])->name('wishlist.move-to-cart');
        Route::post('/wishlist/{product}', [WishlistController::class, 'toggle'])->name('wishlist.toggle');
        Route::delete('/wishlist/{product}', [WishlistController::class, 'destroy'])->name('wishlist.destroy');
        Route::get('/profile', [ProfileController::class, 'show'])->name('profile.show');
        Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');
        Route::put('/password', [ProfileController::class, 'updatePassword'])->name('password.update');
        Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');

        /*
        |----------------------------------------------------------------------
        | Referral Programme
        |----------------------------------------------------------------------
        |
        | Required from inside this group so the referral page inherits the same
        | prefix, auth middleware and theme layout as the rest of the account.
        |
        */
        require base_path('packages/Cartxis/Referral/src/Routes/shop.php');

        /*
        |----------------------------------------------------------------------
        | Identity Verification
        |----------------------------------------------------------------------
        |
        | Required from inside this group for the same reason: the customer's
        | identity page needs the shop's theme layout, session and auth.
        |
        */
        require base_path('packages/Cartxis/Identity/src/Routes/shop.php');
    });

    /*
    |--------------------------------------------------------------------------
    | Referral Invitation Landing (public)
    |--------------------------------------------------------------------------
    |
    | Someone who has followed a shared link but has no account yet. It explains
    | the offer before they are asked to sign up, and it works without a theme
    | layout because it is a single page.
    */
    Route::get('/referral/{code?}', [ReferralDashboardController::class, 'landing'])
        ->name('shop.referral.landing');

    /*
    |--------------------------------------------------------------------------
    | Checkout Routes
    |--------------------------------------------------------------------------
    */
    Route::group([
        'prefix' => 'checkout',
        'as' => 'shop.checkout.',
    ], function () {
        Route::get('/', [CheckoutController::class, 'index'])->name('index');
        Route::post('/', [CheckoutController::class, 'store'])
            ->middleware(['throttle:10,1', 'customer.verified'])
            ->name('store');
        Route::post('/shipping', [CheckoutController::class, 'updateShipping'])->middleware('throttle:20,1')->name('shipping.update');
        Route::get('/success/{order}', [CheckoutController::class, 'success'])->name('success');
        Route::get('/track-order', [CheckoutController::class, 'guestTrack'])->name('track');
        Route::post('/track-order', [CheckoutController::class, 'guestTrackLookup'])->name('track.lookup');
    });

    /*
    |--------------------------------------------------------------------------
    | Account Deletion Info (public — required by Google Play / App Store)
    |--------------------------------------------------------------------------
    */
    Route::get('/account-deletion', [ProfileController::class, 'deletionInfo'])->name('account.deletion');
});
