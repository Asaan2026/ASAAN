<?php

namespace Cartxis\Shop\Providers;

use Cartxis\Admin\Services\AdminNotificationService;
use Cartxis\Shop\Contracts\CategoryRepositoryInterface;
use Cartxis\Shop\Contracts\OrderRepositoryInterface;
use Cartxis\Shop\Contracts\ProductRepositoryInterface;
use Cartxis\Shop\Http\Middleware\ShareFrontendData;
use Cartxis\Shop\Repositories\CategoryRepository;
use Cartxis\Shop\Repositories\OrderRepository;
use Cartxis\Shop\Repositories\ProductRepository;
use Cartxis\Shop\Services\CategoryService;
use Cartxis\Shop\Services\CheckoutService;
use Cartxis\Shop\Services\HomeService;
use Cartxis\Shop\Services\ProductService;
use Illuminate\Support\ServiceProvider;

class ShopServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     *
     * @return void
     */
    public function register()
    {
        $this->registerConfig();
        $this->registerRepositories();
        $this->registerServices();
    }

    /**
     * Bootstrap services.
     *
     * @return void
     */
    public function boot()
    {
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');

        $this->loadRoutesFrom(__DIR__.'/../Routes/web.php');
        $this->loadRoutesFrom(__DIR__.'/../Routes/api.php');

        $this->loadViewsFrom(__DIR__.'/../Resources/views', 'shop');

        $this->loadTranslationsFrom(__DIR__.'/../Resources/lang', 'shop');

        $this->publishes([
            __DIR__.'/../Resources/assets' => public_path('vendor/shop'),
        ], 'shop-assets');

        // Register middleware for frontend data sharing
        $this->registerMiddleware();
    }

    /**
     * Register middleware.
     *
     * @return void
     */
    protected function registerMiddleware()
    {
        $router = $this->app['router'];

        // Add setup incomplete check to web middleware group
        $router->pushMiddlewareToGroup('web', 'setup.incomplete');

        // Add to web middleware group
        $router->pushMiddlewareToGroup('web', ShareFrontendData::class);
    }

    /**
     * Register package config.
     *
     * @return void
     */
    protected function registerConfig()
    {
        $this->mergeConfigFrom(
            dirname(__DIR__).'/Config/shop.php',
            'shop'
        );
    }

    /**
     * Register repositories.
     *
     * @return void
     */
    protected function registerRepositories()
    {
        $this->app->singleton(
            ProductRepositoryInterface::class,
            ProductRepository::class
        );

        $this->app->singleton(
            CategoryRepositoryInterface::class,
            CategoryRepository::class
        );

        $this->app->singleton(
            OrderRepositoryInterface::class,
            OrderRepository::class
        );
    }

    /**
     * Register services.
     *
     * @return void
     */
    protected function registerServices()
    {
        $this->app->singleton(
            HomeService::class,
            function ($app) {
                return new HomeService(
                    $app->make(ProductRepositoryInterface::class),
                    $app->make(CategoryRepositoryInterface::class)
                );
            }
        );

        $this->app->singleton(
            ProductService::class,
            function ($app) {
                return new ProductService(
                    $app->make(ProductRepositoryInterface::class)
                );
            }
        );

        $this->app->singleton(
            CategoryService::class,
            function ($app) {
                return new CategoryService(
                    $app->make(CategoryRepositoryInterface::class)
                );
            }
        );

        $this->app->singleton(
            CheckoutService::class,
            function ($app) {
                return new CheckoutService(
                    $app->make(OrderRepositoryInterface::class),
                    $app->make(AdminNotificationService::class)
                );
            }
        );
    }
}
