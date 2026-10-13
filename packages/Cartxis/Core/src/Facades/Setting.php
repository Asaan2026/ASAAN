<?php

namespace Cartxis\Core\Facades;

use Cartxis\Core\Models\Setting as SettingModel;
use Cartxis\Core\Services\SettingService;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Facade;

/**
 * @method static mixed get(string $key, $default = null)
 * @method static SettingModel set(string $key, $value, string $type = 'string', string|null $group = null)
 * @method static bool has(string $key)
 * @method static bool delete(string $key)
 * @method static Collection getGroup(string $group)
 * @method static Collection getPublic()
 * @method static void setMultiple(array $settings, string|null $group = null)
 * @method static void clearCache()
 * @method static Collection all()
 * @method static Collection getByExtension(string $extensionCode)
 * @method static bool deleteByExtension(string $extensionCode)
 *
 * @see SettingService
 */
class Setting extends Facade
{
    /**
     * Get the registered name of the component.
     */
    protected static function getFacadeAccessor(): string
    {
        return 'cartxis.setting';
    }
}
