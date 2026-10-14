<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Give the demo shop's categories a cover picture.
 *
 * The Dari demo seeder used to create the categories without any image, so the
 * category section on the storefront showed an empty box. The seeder now sets
 * them, but an already-provisioned database is never seeded again, so the
 * existing rows need the covers applied here. The files sit in
 * public/images/categories/ and are served straight from the app.
 */
return new class extends Migration
{
    /**
     * @var array<string, string>
     */
    private array $covers = [
        'mobile-tablets' => '/images/categories/mobile-tablets.jpg',
        'laptops-computers' => '/images/categories/laptops-computers.jpg',
        'home-appliances' => '/images/categories/home-appliances.jpg',
        'clothing' => '/images/categories/clothing.jpg',
        'groceries' => '/images/categories/groceries.jpg',
        'beauty-health' => '/images/categories/beauty-health.jpg',
        'sports' => '/images/categories/sports.jpg',
        'books-stationery' => '/images/categories/books-stationery.jpg',
    ];

    public function up(): void
    {
        if (! Schema::hasTable('categories')) {
            return;
        }

        foreach ($this->covers as $slug => $image) {
            DB::table('categories')
                ->where('slug', $slug)
                ->where(function ($query) {
                    $query->whereNull('image')->orWhere('image', '');
                })
                ->update(['image' => $image, 'updated_at' => now()]);
        }
    }

    public function down(): void
    {
        // Only fills blanks; nothing to safely revert without risking a real
        // cover someone uploaded later.
    }
};
