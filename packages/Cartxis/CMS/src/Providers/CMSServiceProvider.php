<?php

declare(strict_types=1);

namespace Cartxis\CMS\Providers;

use Cartxis\CMS\Repositories\BlockRepository;
use Cartxis\CMS\Repositories\PageRepository;
use Cartxis\CMS\Services\BlockService;
use Cartxis\CMS\Services\PageService;
use Cartxis\CMS\Services\StorefrontMenuService;
use Cartxis\CMS\Services\StorefrontMenuSyncService;
use Illuminate\Support\Facades\Blade;
use Illuminate\Support\ServiceProvider;

class CMSServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        // Merge configuration
        $this->mergeConfigFrom(
            __DIR__.'/../config/cms.php',
            'cms'
        );

        // Register services
        $this->app->singleton(PageService::class);
        $this->app->singleton(PageRepository::class);
        $this->app->singleton(BlockService::class);
        $this->app->singleton(BlockRepository::class);
        $this->app->singleton(StorefrontMenuSyncService::class);
        $this->app->singleton(StorefrontMenuService::class);
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        // Load migrations
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');

        // Load routes
        $this->loadRoutesFrom(__DIR__.'/../Routes/admin.php');
        $this->loadRoutesFrom(__DIR__.'/../Routes/web.php');

        // Publish configuration
        $this->publishes([
            __DIR__.'/../config/cms.php' => config_path('cms.php'),
        ], 'cms-config');

        // Register @block Blade directive
        $this->registerBlockDirective();
    }

    /**
     * Register @block Blade directive for rendering blocks.
     */
    protected function registerBlockDirective(): void
    {
        Blade::directive('block', function ($expression) {
            return "<?php echo app(\Cartxis\CMS\Services\BlockService::class)->renderBlock(app(\Cartxis\CMS\Repositories\BlockRepository::class)->findByIdentifier({$expression})); ?>";
        });
    }
}
