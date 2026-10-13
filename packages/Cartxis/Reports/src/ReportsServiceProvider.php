<?php

namespace Cartxis\Reports;

use Cartxis\Reports\Services\CustomerReportService;
use Cartxis\Reports\Services\DeliveryReportService;
use Cartxis\Reports\Services\ProductReportService;
use Cartxis\Reports\Services\ReportCacheService;
use Cartxis\Reports\Services\SalesReportService;
use Illuminate\Support\ServiceProvider;

class ReportsServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Merge config
        $this->mergeConfigFrom(
            __DIR__.'/Config/reports.php',
            'reports'
        );

        // Register services
        $this->app->singleton(SalesReportService::class);
        $this->app->singleton(ProductReportService::class);
        $this->app->singleton(CustomerReportService::class);
        $this->app->singleton(ReportCacheService::class);
        $this->app->singleton(DeliveryReportService::class);
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Load routes
        $this->loadRoutesFrom(__DIR__.'/Routes/admin.php');

        // Load views
        $this->loadViewsFrom(__DIR__.'/Views', 'reports');

        // Publish config
        $this->publishes([
            __DIR__.'/Config/reports.php' => config_path('reports.php'),
        ], 'reports-config');

        // Publish views
        $this->publishes([
            __DIR__.'/Views' => resource_path('views/vendor/reports'),
        ], 'reports-views');
    }
}
