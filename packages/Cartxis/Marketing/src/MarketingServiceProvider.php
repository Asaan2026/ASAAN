<?php

namespace Cartxis\Marketing;

use Cartxis\Marketing\Services\CouponService;
use Cartxis\Marketing\Services\DiscountCalculator;
use Cartxis\Marketing\Services\PromotionService;
use Illuminate\Support\ServiceProvider;

class MarketingServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Register services
        $this->app->singleton(CouponService::class);
        $this->app->singleton(PromotionService::class);
        $this->app->singleton(DiscountCalculator::class);
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Load admin routes
        $this->loadRoutesFrom(__DIR__.'/Routes/admin.php');

        // Load shop (frontend) routes
        $this->loadRoutesFrom(__DIR__.'/Routes/shop.php');

        // Load migrations
        $this->loadMigrationsFrom(__DIR__.'/Database/Migrations');

        // Publish config (optional)
        if ($this->app->runningInConsole()) {
            $this->publishes([
                __DIR__.'/Config/marketing.php' => config_path('marketing.php'),
            ], 'marketing-config');
        }
    }
}
