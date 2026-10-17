<?php

use Cartxis\Product\Models\Category;

/*
|--------------------------------------------------------------------------
| The cover image the app shows for each category
|--------------------------------------------------------------------------
|
| The app builds its category tiles from the "image" field on this endpoint.
| The old code ran the value through the storage disk helper, which turned a
| file shipped in public/images/... into "/storage//images/..." -- a link that
| does not exist on the server, so the app showed nothing. These tests hold the
| field to a full, loadable web address.
|
*/

function makeCategory(array $overrides = []): Category
{
    return Category::create(array_merge([
        'name' => 'Mobile & Tablets',
        'slug' => 'mobile-tablets',
        'status' => 'enabled',
        'sort_order' => 1,
        'show_in_menu' => true,
        'left' => 1,
        'right' => 2,
        'depth' => 0,
    ], $overrides));
}

it('points a shipped cover image at a full public web address', function () {
    makeCategory(['image' => '/images/categories/mobile-tablets.jpg']);

    $image = collect($this->getJson('/api/v1/categories')->assertOk()->json('data'))
        ->firstWhere('slug', 'mobile-tablets')['image'];

    expect($image)->toBe(url('/images/categories/mobile-tablets.jpg'))
        ->and($image)->not->toContain('/storage//');
});

it('points an uploaded cover image at the public storage link', function () {
    makeCategory(['image' => 'categories/my-own-cover.jpg']);

    $image = collect($this->getJson('/api/v1/categories')->assertOk()->json('data'))
        ->firstWhere('slug', 'mobile-tablets')['image'];

    expect($image)->toBe(url('storage/categories/my-own-cover.jpg'));
});

it('returns no image when the category has no cover', function () {
    makeCategory(['image' => null]);

    $image = collect($this->getJson('/api/v1/categories')->assertOk()->json('data'))
        ->firstWhere('slug', 'mobile-tablets')['image'];

    expect($image)->toBeNull();
});
