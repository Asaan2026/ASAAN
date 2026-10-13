<?php

namespace Cartxis\Core\Facades;

use Cartxis\Core\Models\MenuItem;
use Cartxis\Core\Services\MenuService;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Facade;

/**
 * @method static Collection buildTree(string $location = 'admin')
 * @method static MenuItem register(array $data)
 * @method static bool unregister(string $key)
 * @method static bool update(string $key, array $data)
 * @method static MenuItem|null getByKey(string $key)
 * @method static Collection getByExtension(string $extensionCode)
 * @method static bool removeByExtension(string $extensionCode)
 * @method static void reorder(array $items)
 * @method static Collection getFlatList(string $location = 'admin')
 *
 * @see MenuService
 */
class Menu extends Facade
{
    /**
     * Get the registered name of the component.
     */
    protected static function getFacadeAccessor(): string
    {
        return 'cartxis.menu';
    }
}
