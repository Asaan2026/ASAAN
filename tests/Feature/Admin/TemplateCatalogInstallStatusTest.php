<?php

declare(strict_types=1);

use Cartxis\Core\Models\Theme;
use Cartxis\Core\Services\TemplateCatalogService;
use Cartxis\Core\Services\ThemeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;

uses(RefreshDatabase::class);

/**
 * Give each test run its own template catalog.
 *
 * These tests used to build theme packages inside the real templates/
 * directory and delete it again, so two of them running at once in different
 * parallel processes pulled files out from under each other. The theme root
 * is a config value, so each run gets its own.
 */
beforeEach(function () {
    $this->catalogRoot = storage_path(
        'framework/testing/theme-catalog-'.(getenv('TEST_TOKEN') ?: 'seq').'-'.Str::random(8)
    );

    config(['theme.catalog_path' => $this->catalogRoot]);
    File::ensureDirectoryExists($this->catalogRoot.'/storefront');

    // The shipped default has to be present: code elsewhere treats it as
    // always installed, and these tests assert that.
    $default = $this->catalogRoot.'/storefront/general/cartxis-default';
    foreach (['pages', 'components', 'layouts'] as $folder) {
        File::ensureDirectoryExists($default.'/resources/views/'.$folder);
    }
    File::put($default.'/theme.json', json_encode([
        'name' => 'Cartxis Default',
        'slug' => 'cartxis-default',
        'version' => '1.0.0',
        'author' => 'Cartxis',
        'is_default' => true,
    ], JSON_PRETTY_PRINT));
});

afterEach(function () {
    File::deleteDirectory($this->catalogRoot);
});

test('catalog-only storefront packages are not marked installed until explicitly installed', function () {
    $categoryPath = $this->catalogRoot.'/storefront/electronics';
    $packagePath = $categoryPath.'/dmart-electronics';

    File::ensureDirectoryExists($packagePath.'/resources/views/pages');
    File::ensureDirectoryExists($packagePath.'/resources/views/components');
    File::ensureDirectoryExists($packagePath.'/resources/views/layouts');

    File::put($packagePath.'/theme.json', json_encode([
        'name' => 'Dmart Electronics',
        'slug' => 'dmart-electronics',
        'version' => '1.0.0',
        'author' => 'Cartxis',
    ], JSON_PRETTY_PRINT));

    File::put($packagePath.'/template.json', json_encode([
        'slug' => 'dmart-electronics',
        'type' => 'storefront',
        'category' => 'electronics',
        'name' => 'Dmart Electronics',
        'description' => 'Electronics demo theme',
        'version' => '1.0.0',
        'author' => 'Cartxis',
    ], JSON_PRETTY_PRINT));

    app(ThemeService::class)->discover();

    expect(Theme::where('slug', 'dmart-electronics')->exists())->toBeFalse();

    $catalog = app(TemplateCatalogService::class);
    $entry = $catalog->discover('storefront')->firstWhere('slug', 'dmart-electronics');

    expect($entry)->not->toBeNull()
        ->and($entry['installed'])->toBeFalse()
        ->and($catalog->isInstalled('dmart-electronics'))->toBeFalse()
        ->and($catalog->isInstalled('cartxis-default'))->toBeTrue();

    File::deleteDirectory($categoryPath);
});
