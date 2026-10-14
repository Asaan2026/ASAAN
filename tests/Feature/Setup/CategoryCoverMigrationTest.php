<?php

use Cartxis\Product\Models\Category;
use Illuminate\Support\Facades\DB;

/**
 * The live store was already provisioned, so it never runs the demo seeder
 * again. The category covers for that database arrive through a migration, so
 * this checks that migration actually fills a blank cover.
 */
test('the category cover migration fills a blank cover on an existing shop', function () {
    DB::table('categories')->insert([
        'name' => 'موبایل و تبلت',
        'slug' => 'mobile-tablets',
        'image' => null,
        'status' => 'enabled',
        'sort_order' => 1,
        'show_in_menu' => true,
        'left' => 1,
        'right' => 2,
        'depth' => 0,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    $migration = require base_path('packages/Cartxis/Product/src/Database/Migrations/2026_10_13_200000_add_category_cover_images.php');
    $migration->up();

    expect(DB::table('categories')->where('slug', 'mobile-tablets')->value('image'))
        ->toBe('/images/categories/mobile-tablets.jpg');
});

test('the category cover migration never overwrites a cover someone already set', function () {
    DB::table('categories')->insert([
        'slug' => 'groceries',
        'name' => 'مواد غذایی',
        'image' => 'categories/my-own-cover.jpg',
        'status' => 'enabled',
        'sort_order' => 1,
        'show_in_menu' => true,
        'left' => 1,
        'right' => 2,
        'depth' => 0,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    $migration = require base_path('packages/Cartxis/Product/src/Database/Migrations/2026_10_13_200000_add_category_cover_images.php');
    $migration->up();

    expect(DB::table('categories')->where('slug', 'groceries')->value('image'))
        ->toBe('categories/my-own-cover.jpg');
});
