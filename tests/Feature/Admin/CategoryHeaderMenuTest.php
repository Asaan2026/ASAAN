<?php

use App\Models\User;
use Cartxis\CMS\Database\Seeders\StorefrontMenuSeeder;
use Cartxis\Product\Models\Category;
use Illuminate\Support\Facades\DB;

/**
 * The header "Categories" menu is built from menu rows, not from the
 * categories table. Anything the owner does on the category screen has to
 * rebuild those rows, or a category added in the dashboard never appears in
 * the shop header.
 */
beforeEach(function () {
    $this->seed(StorefrontMenuSeeder::class);

    $this->admin = User::factory()->withoutTwoFactor()->create([
        'role' => 'admin',
        'is_active' => true,
    ]);
});

test('a category added in the dashboard lands in the header menu', function () {
    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Home Care',
            'slug' => 'home-care',
            'status' => 'enabled',
            'show_in_menu' => '1',
        ])
        ->assertRedirect(route('admin.catalog.categories.index'));

    $this->assertDatabaseHas('categories', [
        'slug' => 'home-care',
        'show_in_menu' => true,
    ]);

    $parentId = DB::table('menu_items')
        ->where('key', 'categories')
        ->where('location', 'storefront')
        ->value('id');

    $this->assertDatabaseHas('menu_items', [
        'key' => 'category-home-care',
        'location' => 'storefront',
        'parent_id' => $parentId,
        'url' => '/category/home-care',
        'menu_type' => 'header',
        'active' => true,
    ]);
});

test('the show in menu switch is saved and keeps the category out of the menu', function () {
    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Hidden Shelf',
            'slug' => 'hidden-shelf',
            'status' => 'enabled',
            'show_in_menu' => '0',
        ]);

    $this->assertDatabaseHas('categories', [
        'slug' => 'hidden-shelf',
        'show_in_menu' => false,
    ]);

    $this->assertDatabaseMissing('menu_items', [
        'key' => 'category-hidden-shelf',
    ]);
});

test('renaming the slug moves the header link to the new address', function () {
    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Seasonal',
            'slug' => 'seasonal-old',
            'status' => 'enabled',
            'show_in_menu' => '1',
        ]);

    $id = Category::where('slug', 'seasonal-old')->value('id');

    $this->actingAs($this->admin, 'admin')
        ->put('/admin/catalog/categories/'.$id, [
            'name' => 'Seasonal Picks',
            'slug' => 'seasonal-new',
            'status' => 'enabled',
            'show_in_menu' => '1',
        ])
        ->assertRedirect();

    $this->assertDatabaseHas('menu_items', [
        'key' => 'category-seasonal-new',
        'url' => '/category/seasonal-new',
        'active' => true,
    ]);

    expect((bool) DB::table('menu_items')->where('key', 'category-seasonal-old')->value('active'))
        ->toBeFalse();
});

test('deleting a category takes it out of the header menu', function () {
    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Short Lived',
            'slug' => 'short-lived',
            'status' => 'enabled',
            'show_in_menu' => '1',
        ]);

    $id = Category::where('slug', 'short-lived')->value('id');

    $this->actingAs($this->admin, 'admin')
        ->delete('/admin/catalog/categories/'.$id)
        ->assertRedirect(route('admin.catalog.categories.index'));

    expect((bool) DB::table('menu_items')->where('key', 'category-short-lived')->value('active'))
        ->toBeFalse();
});

/**
 * The homepage used to hand the header its own cached category list built
 * from every root category, ignoring the "Show in Navigation Menu" switch.
 * The header must get the same list as the rest of the shop: shown, enabled
 * categories only.
 */
test('the home page header uses the same category list as the rest of the shop', function () {
    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Home Care',
            'slug' => 'home-care',
            'status' => 'enabled',
            'show_in_menu' => '1',
        ]);

    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Hidden Shelf',
            'slug' => 'hidden-shelf',
            'status' => 'enabled',
            'show_in_menu' => '0',
        ]);

    $props = $this->get('/')->viewData('page')['props'];
    $slugs = collect($props['categories'])->pluck('slug');

    expect($slugs)->toContain('home-care');
    expect($slugs)->not->toContain('hidden-shelf');
});

test('the home page cached category data refreshes when a category changes', function () {
    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Home Care',
            'slug' => 'home-care',
            'status' => 'enabled',
            'show_in_menu' => '1',
        ]);

    $first = $this->get('/')->viewData('page')['props'];
    expect(collect($first['featuredCategories'])->pluck('slug'))->toContain('home-care');

    $this->actingAs($this->admin, 'admin')
        ->post('/admin/catalog/categories', [
            'name' => 'Pet Supplies',
            'slug' => 'pet-supplies',
            'status' => 'enabled',
            'show_in_menu' => '1',
        ]);

    $second = $this->get('/')->viewData('page')['props'];
    expect(collect($second['featuredCategories'])->pluck('slug'))->toContain('pet-supplies');
});
