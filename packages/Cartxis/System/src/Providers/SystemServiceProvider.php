<?php

declare(strict_types=1);

namespace Cartxis\System\Providers;

use Cartxis\System\Console\Commands\Migration\WooCommerce\MigrateAllCommand;
use Cartxis\System\Console\Commands\Migration\WooCommerce\MigrateCategoriesCommand;
use Cartxis\System\Console\Commands\Migration\WooCommerce\MigrateCustomersCommand;
use Cartxis\System\Console\Commands\Migration\WooCommerce\MigrateOrdersCommand;
use Cartxis\System\Console\Commands\Migration\WooCommerce\MigrateProductsCommand;
use Illuminate\Support\ServiceProvider;

class SystemServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Merge migration configurations
        $this->mergeConfigFrom(__DIR__.'/../Config/woocommerce-migration.php', 'woocommerce-migration');
        $this->mergeConfigFrom(__DIR__.'/../Config/bagisto-migration.php', 'bagisto-migration');
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Load routes
        $this->loadRoutesFrom(__DIR__.'/../Routes/system.php');

        // Load migrations
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');

        // Load views
        $this->loadViewsFrom(__DIR__.'/../resources/views', 'system');

        // Register migration commands (always register so they can be called via Artisan::call from web)
        $this->commands([
            // WooCommerce migration commands
            MigrateAllCommand::class,
            MigrateCategoriesCommand::class,
            MigrateProductsCommand::class,
            MigrateCustomersCommand::class,
            MigrateOrdersCommand::class,

            // Bagisto migration commands
            \Cartxis\System\Console\Commands\Migration\Bagisto\MigrateAllCommand::class,
            \Cartxis\System\Console\Commands\Migration\Bagisto\MigrateCategoriesCommand::class,
            \Cartxis\System\Console\Commands\Migration\Bagisto\MigrateProductsCommand::class,
            \Cartxis\System\Console\Commands\Migration\Bagisto\MigrateCustomersCommand::class,
            \Cartxis\System\Console\Commands\Migration\Bagisto\MigrateOrdersCommand::class,
        ]);
    }
}
