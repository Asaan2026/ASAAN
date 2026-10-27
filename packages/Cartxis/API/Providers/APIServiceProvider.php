<?php

namespace Cartxis\API\Providers;

use App\Models\User;
use Cartxis\API\Observers\OrderNotificationObserver;
use Cartxis\API\Observers\WelcomeNotificationObserver;
use Cartxis\API\Services\Push\FcmCredentials;
use Cartxis\API\Services\Push\FcmPushSender;
use Cartxis\API\Services\Push\NullPushSender;
use Cartxis\API\Services\Push\PushSender;
use Cartxis\Shop\Models\Order;
use Illuminate\Support\ServiceProvider;

class APIServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Load migrations
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');

        // Load API routes
        $this->loadRoutesFrom(__DIR__.'/../Routes/api.php');

        // Customers hear about their orders through the same notification path
        // the bell reads, whatever changed the order.
        Order::observe(OrderNotificationObserver::class);

        // A brand-new account gets one welcome notification, from whichever
        // path created it, so a fresh bell is never empty.
        User::observe(WelcomeNotificationObserver::class);

        // Load config
        $this->publishes([
            __DIR__.'/../Config/api.php' => config_path('cartxis-api.php'),
        ], 'cartxis-api-config');

        $this->mergeConfigFrom(
            __DIR__.'/../Config/api.php',
            'cartxis-api'
        );
    }

    /**
     * Register services.
     */
    public function register(): void
    {
        // Register API helper
        require_once __DIR__.'/../Helpers/ApiResponse.php';

        // Push notifications: use Firebase when it is set up, and a sender that
        // does nothing when it is not. Callers never have to check.
        $this->app->bind(PushSender::class, function ($app) {
            // The key may come from .env, as it always could, or from the one
            // the owner uploaded in Settings > Notifications. Resolving it here
            // means every caller gets whichever is actually present.
            try {
                $credentials = $app->make(FcmCredentials::class);
                $projectId = $credentials->projectId();
                $keyPath = $credentials->credentialsPath();
            } catch (\Throwable $e) {
                // No database yet (installing, migrating): fall back to .env
                // alone rather than failing to boot.
                $projectId = config('services.fcm.project_id');
                $keyPath = config('services.fcm.credentials');
            }

            $sender = new FcmPushSender(
                $projectId,
                $keyPath,
                (string) config('services.fcm.notification_channel', ''),
            );

            return $sender->isConfigured() ? $sender : new NullPushSender;
        });
    }
}
