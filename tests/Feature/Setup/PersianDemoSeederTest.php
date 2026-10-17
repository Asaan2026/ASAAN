<?php

use App\Models\User;
use Cartxis\CMS\Database\Seeders\StorefrontMenuSeeder;
use Cartxis\Product\Models\Category;
use Cartxis\Product\Models\ProductImage;
use Cartxis\Setup\Database\Seeders\PersianDemoSeeder;
use Cartxis\Setup\Services\DemoDataService;
use Database\Seeders\OrderSeeder;
use Database\Seeders\TransactionSeeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/**
 * The Dari demo shop. This is what an owner gets when they pick the Afghan
 * store during setup, so the whole catalogue has to land in one go.
 */
test('the Dari demo store fills the shop with a full Afghan catalogue', function () {
    $this->seed(PersianDemoSeeder::class);

    // The products table stores visibility as an enum (catalog, search, both,
    // none). SQLite does not enforce enums, so an invalid value such as
    // "visible" passes the tests but is rejected by the live MySQL, which
    // silently dropped every product while still creating the categories.
    foreach (DB::table('products')->pluck('visibility') as $visibility) {
        expect($visibility)->toBeIn(['catalog', 'search', 'both', 'none']);
    }

    expect(DB::table('categories')->count())->toBe(8)
        ->and(DB::table('brands')->count())->toBe(8)
        ->and(DB::table('products')->count())->toBe(24)
        ->and(DB::table('product_images')->count())->toBe(24)
        ->and(DB::table('category_product')->count())->toBe(24)
        ->and(DB::table('service_categories')->count())->toBe(4)
        ->and(DB::table('services')->count())->toBe(10)
        ->and(DB::table('pages')->count())->toBe(5);
});

test('the demo catalogue is written in Dari, not English', function () {
    $this->seed(PersianDemoSeeder::class);

    $this->assertDatabaseHas('categories', ['slug' => 'food-provisions', 'name' => 'مواد ارتزاقی']);
    $this->assertDatabaseHas('services', ['slug' => 'home-cleaning', 'name' => 'پاککاری کامل خانه']);
    $this->assertDatabaseHas('pages', ['url_key' => 'contact-us', 'title' => 'تماس با ما']);

    // Every visible name and description is in the Arabic/Persian script range,
    // so no English placeholder slipped through.
    foreach (DB::table('products')->get(['name', 'description']) as $product) {
        expect($product->name)->toMatch('/[\x{0600}-\x{06FF}]/u')
            ->and($product->description)->toMatch('/[\x{0600}-\x{06FF}]/u');
    }
});

test('the demo shop has orders and transactions to look at', function () {
    $this->seed(PersianDemoSeeder::class);
    $this->seed(OrderSeeder::class);
    $this->seed(TransactionSeeder::class);

    expect(DB::table('orders')->count())->toBeGreaterThan(0)
        ->and(DB::table('order_items')->count())->toBeGreaterThan(0);
});

test('the demo accounts can sign in and have customer profiles', function () {
    $this->seed(PersianDemoSeeder::class);

    $owner = User::where('email', 'demo@asaan.af')->first();

    expect($owner)->not->toBeNull()
        ->and($owner->role)->toBe('admin')
        ->and($owner->is_active)->toBeTrue()
        ->and(Hash::check('Asaan@2026', $owner->password))->toBeTrue();

    $shopper = User::where('email', 'shopper@asaan.af')->first();

    expect($shopper)->not->toBeNull()
        ->and($shopper->role)->toBe('customer')
        // A customer row, so the customer list and reports have somebody in them.
        ->and(DB::table('customers')->where('user_id', $shopper->id)->exists())->toBeTrue();

    foreach (['fatima@asaan.af' => 'فاطمه', 'karim@asaan.af' => 'کریم'] as $email => $firstName) {
        $buyer = User::where('email', $email)->firstOrFail();

        $this->assertDatabaseHas('customers', [
            'user_id' => $buyer->id,
            'first_name' => $firstName,
        ]);
    }
});

test('the demo product photos are bundled with the app, not loaded from an outside site', function () {
    $this->seed(PersianDemoSeeder::class);

    $images = DB::table('product_images')->get(['path', 'thumbnail_path']);

    expect($images)->not->toBeEmpty();

    foreach ($images as $image) {
        expect($image->path)->toStartWith('/images/catalog/products/')
            ->and($image->thumbnail_path)->toStartWith('/images/catalog/products/')
            ->and(is_file(public_path(ltrim($image->path, '/'))))->toBeTrue();
    }
});

test('image links resolve for outside links, bundled files and storage files', function () {
    expect(ProductImage::urlFor('https://example.com/a.jpg'))->toBe('https://example.com/a.jpg')
        ->and(ProductImage::urlFor('/images/catalog/products/almonds.jpg'))->toContain('/images/catalog/products/almonds.jpg')
        ->and(ProductImage::urlFor('/images/catalog/products/almonds.jpg'))->not->toContain('/storage/')
        ->and(ProductImage::urlFor('products/a.jpg'))->toContain('/storage/products/a.jpg')
        ->and(ProductImage::urlFor(null))->toBeNull();
});

test('the demo categories have a cover image that is bundled with the app', function () {
    $this->seed(PersianDemoSeeder::class);

    $categories = DB::table('categories')->get(['slug', 'image']);

    expect($categories)->not->toBeEmpty();

    foreach ($categories as $category) {
        expect($category->image)->toStartWith('/images/catalog/categories/')
            ->and(is_file(public_path(ltrim($category->image, '/'))))->toBeTrue();
    }
});

test('a category cover that ships in public/ is served from the app, not the storage link', function () {
    $category = new Category(['image' => '/images/catalog/categories/nuts.jpg']);

    expect($category->image_url)->toContain('/images/catalog/categories/nuts.jpg')
        ->and($category->image_url)->not->toContain('/storage/');
});

test('the demo store can be seeded again without duplicating anything', function () {
    $this->seed(PersianDemoSeeder::class);
    $this->seed(PersianDemoSeeder::class);

    expect(DB::table('products')->count())->toBe(24)
        ->and(DB::table('product_images')->count())->toBe(24)
        ->and(DB::table('category_product')->count())->toBe(24)
        ->and(DB::table('services')->count())->toBe(10)
        ->and(DB::table('customers')->count())->toBe(3)
        ->and(User::where('email', 'shopper@asaan.af')->count())->toBe(1);
});

test('the Afghan store is offered first during setup', function () {
    $types = app(DemoDataService::class)->getBusinessTypes();

    expect($types)->not->toBeEmpty()
        ->and($types[0]['id'])->toBe('persian');
});

/**
 * The catalogue the owner actually asked for: eight categories, each with its
 * own name in Dari, its own cover, and nothing contradictory left over.
 */
test('the shop is filled with the exact eight categories the owner asked for', function () {
    $this->seed(PersianDemoSeeder::class);

    $categories = DB::table('categories')
        ->whereNull('parent_id')
        ->orderBy('sort_order')
        ->get(['name', 'slug', 'image', 'status', 'show_in_menu']);

    expect($categories->pluck('slug')->all())->toBe([
        'food-provisions',
        'toiletries',
        'electrical-appliances',
        'clothing',
        'kids',
        'dried-fruit',
        'gifts',
        'nuts',
    ]);

    expect($categories->pluck('name')->all())->toBe([
        'مواد ارتزاقی',
        'لوازم بهداشتی',
        'لوازم برقی',
        'پوشاک',
        'بخش اطفال',
        'میوه خشک',
        'تحایف و هدیه ها',
        'خشکبار',
    ]);

    foreach ($categories as $category) {
        expect($category->status)->toBe('enabled')
            ->and((bool) $category->show_in_menu)->toBeTrue()
            ->and($category->name)->toMatch('/[\x{0600}-\x{06FF}]/u');
    }
});

/**
 * The shop used to ship phones, laptops and sports gear. Those categories and
 * products contradict a grocery and household store, so a fresh run of the
 * seeder has to take them out rather than leave them side by side.
 */
test('the old demo catalogue is replaced, not piled on top of', function () {
    DB::table('categories')->insert([
        'name' => 'مواد غذایی', 'slug' => 'groceries', 'parent_id' => null,
        'status' => 'enabled', 'show_in_menu' => true, 'sort_order' => 5,
        'created_at' => now(), 'updated_at' => now(),
    ]);

    $productId = DB::table('products')->insertGetId([
        'name' => 'برنج سیله', 'sku' => 'GR-RICE', 'slug' => 'product-GR-RICE',
        'type' => 'simple', 'price' => 2600, 'status' => 'enabled',
        'visibility' => 'both', 'quantity' => 200, 'manage_stock' => true,
        'stock_status' => 'in_stock', 'min_quantity' => 1,
        'created_at' => now(), 'updated_at' => now(),
    ]);

    DB::table('product_images')->insert([
        'product_id' => $productId, 'path' => '/images/products/x.jpg',
        'thumbnail_path' => '/images/products/x.jpg', 'position' => 0,
        'created_at' => now(), 'updated_at' => now(),
    ]);

    $this->seed(PersianDemoSeeder::class);

    $this->assertDatabaseMissing('categories', ['slug' => 'groceries']);
    $this->assertDatabaseMissing('products', ['sku' => 'GR-RICE']);
    $this->assertDatabaseMissing('product_images', ['product_id' => $productId]);

    expect(DB::table('categories')->count())->toBe(8);
    expect(DB::table('products')->count())->toBe(24);
});

/**
 * The seeder may only tidy up after itself. A category or product the owner
 * added by hand must survive a demo-catalogue refresh untouched.
 */
test('a category or product the owner made by hand survives the demo catalogue', function () {
    DB::table('categories')->insert([
        'name' => 'بهداشتی', 'slug' => 'bhdashty', 'parent_id' => null,
        'status' => 'enabled', 'show_in_menu' => true, 'sort_order' => 99,
        'created_at' => now(), 'updated_at' => now(),
    ]);

    DB::table('products')->insert([
        'name' => 'محصول خودم', 'sku' => 'MY-001', 'slug' => 'my-001',
        'type' => 'simple', 'price' => 100, 'status' => 'enabled',
        'visibility' => 'both', 'quantity' => 5, 'manage_stock' => true,
        'stock_status' => 'in_stock', 'min_quantity' => 1,
        'created_at' => now(), 'updated_at' => now(),
    ]);

    $this->seed(PersianDemoSeeder::class);

    $this->assertDatabaseHas('categories', ['slug' => 'bhdashty']);
    $this->assertDatabaseHas('products', ['sku' => 'MY-001']);

    // The eight demo categories, plus the one the owner made.
    expect(DB::table('categories')->whereNull('parent_id')->count())->toBe(9);
});

test('every demo product sits in its own category and carries its own photo', function () {
    $this->seed(PersianDemoSeeder::class);

    $expected = [
        'FOOD-RICE5' => 'food-provisions',
        'FOOD-OIL5' => 'food-provisions',
        'FOOD-FLOUR10' => 'food-provisions',
        'HYG-SOAP' => 'toiletries',
        'HYG-SHAMPOO' => 'toiletries',
        'HYG-CREAM' => 'toiletries',
        'ELE-KETTLE' => 'electrical-appliances',
        'ELE-FAN' => 'electrical-appliances',
        'ELE-IRON' => 'electrical-appliances',
        'CLO-SHIRT' => 'clothing',
        'CLO-SHAWL' => 'clothing',
        'CLO-JACKET' => 'clothing',
        'KID-OUTFIT' => 'kids',
        'KID-TOY' => 'kids',
        'KID-DIAPERS' => 'kids',
        'FRU-MULB' => 'dried-fruit',
        'FRU-FIGS' => 'dried-fruit',
        'FRU-PLUM' => 'dried-fruit',
        'GFT-BOX' => 'gifts',
        'GFT-PERFUME' => 'gifts',
        'GFT-VASE' => 'gifts',
        'NUT-ALMOND' => 'nuts',
        'NUT-PISTA' => 'nuts',
        'NUT-MIXED' => 'nuts',
    ];

    foreach ($expected as $sku => $categorySlug) {
        $product = DB::table('products')->where('sku', $sku)->first();

        expect($product)->not->toBeNull("Missing demo product {$sku}");

        $image = DB::table('product_images')->where('id', $product->main_image_id)->first();

        expect($image)->not->toBeNull("Missing photo for {$sku}")
            ->and($image->path)->toBe('/images/catalog/products/'.$product->slug.'.jpg')
            ->and(is_file(public_path(ltrim($image->path, '/'))))->toBeTrue();

        $linked = DB::table('category_product')
            ->join('categories', 'categories.id', '=', 'category_product.category_id')
            ->where('category_product.product_id', $product->id)
            ->value('categories.slug');

        expect($linked)->toBe($categorySlug);
    }
});

test('the shop header lists the eight new categories', function () {
    $this->seed(StorefrontMenuSeeder::class);
    $this->seed(PersianDemoSeeder::class);

    $props = $this->get('/')->viewData('page')['props'];

    expect(collect($props['categories'])->pluck('slug')->all())->toBe([
        'food-provisions',
        'toiletries',
        'electrical-appliances',
        'clothing',
        'kids',
        'dried-fruit',
        'gifts',
        'nuts',
    ]);
});
