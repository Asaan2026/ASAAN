<?php

namespace Cartxis\Sales\Providers;

use Cartxis\Sales\Repositories\InvoiceRepository;
use Cartxis\Sales\Repositories\OrderRepository;
use Cartxis\Sales\Repositories\TransactionRepository;
use Cartxis\Sales\Services\InvoiceService;
use Cartxis\Sales\Services\OrderService;
use Cartxis\Sales\Services\TransactionService;
use Illuminate\Support\ServiceProvider;

class SalesServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Register repositories
        $this->app->singleton(OrderRepository::class);
        $this->app->singleton(InvoiceRepository::class);
        $this->app->singleton(TransactionRepository::class);

        // Register services
        $this->app->singleton(OrderService::class);
        $this->app->singleton(InvoiceService::class);
        $this->app->singleton(TransactionService::class);
    }

    public function boot(): void
    {
        // Load migrations
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');

        // Load routes
        $this->loadRoutesFrom(__DIR__.'/../Routes/admin.php');
        $this->loadRoutesFrom(__DIR__.'/../Routes/delivery.php');

        // Load views
        $this->loadViewsFrom(__DIR__.'/../resources/views', 'sales');
    }
}
