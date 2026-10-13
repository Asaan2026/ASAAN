<?php

namespace Cartxis\Core\Facades;

use Cartxis\Core\Services\ThemeService;
use Illuminate\Support\Facades\Facade;

/**
 * @method static array discover()
 * @method static \Cartxis\Core\Models\Theme|null active()
 * @method static bool activate(string $slug)
 * @method static bool install(string $zipPath)
 * @method static bool delete(string $slug)
 * @method static array getSettingsSchema(\Cartxis\Core\Models\Theme $theme)
 * @method static void loadAssets(\Cartxis\Core\Models\Theme|null $theme = null)
 *
 * @see ThemeService
 */
class Theme extends Facade
{
    /**
     * Get the registered name of the component.
     */
    protected static function getFacadeAccessor(): string
    {
        return 'cartxis.theme';
    }
}
