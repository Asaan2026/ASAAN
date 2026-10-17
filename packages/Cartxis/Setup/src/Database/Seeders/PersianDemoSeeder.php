<?php

declare(strict_types=1);

namespace Cartxis\Setup\Database\Seeders;

use App\Models\User;
use Cartxis\Product\Models\Product;
use Cartxis\Service\Models\Service;
use Cartxis\Service\Models\ServiceCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * A ready-to-sell Afghan store, written in Dari (Persian).
 *
 * The other demo seeders are English and priced for a generic market. This one
 * gives the shop a real Afghan catalogue: household categories, a handful of
 * products people actually buy, a services book (cleaning, repairs, beauty,
 * moving), store pages, and two login accounts to try it with.
 *
 * Prices are written straight in AFN, because AFN is the store's base currency.
 * Category and product photos ship with the app (public/images/catalog), so the
 * seed never has to reach the network while it runs and the pictures still load
 * on a slow connection. Running the seed again replaces the catalogue it made
 * last time -- it never touches a category or a product the owner added by hand.
 */
class PersianDemoSeeder extends Seeder
{
    /**
     * Run the database seeds for the Persian (Dari) business type.
     */
    public function run(): void
    {
        $this->seedCategories();
        $this->seedBrands();
        $this->seedProducts();
        $this->seedServiceCategories();
        $this->seedServices();
        $this->seedPages();
        $this->seedBlocks();
        $this->seedDemoAccounts();
    }

    /**
     * The shop's product categories, in Dari.
     *
     * Every category is a normal row in the `categories` table, so the shop owner
     * can rename, re-picture, reorder or delete any of them from the dashboard
     * afterwards. Nothing here is hard-coded into the storefront.
     */
    private function seedCategories(): void
    {
        $this->removeSupersededCategories();

        $categories = [
            ['name' => 'مواد ارتزاقی', 'slug' => 'food-provisions', 'image' => '/images/catalog/categories/food-provisions.jpg', 'description' => 'برنج، روغن، آرد و سایر مواد اولیه مورد ضرورت خانه'],
            ['name' => 'لوازم بهداشتی', 'slug' => 'toiletries', 'image' => '/images/catalog/categories/toiletries.jpg', 'description' => 'صابون، شامپو، کرم و لوازم پاکی و بهداشت شخصی'],
            ['name' => 'لوازم برقی', 'slug' => 'electrical-appliances', 'image' => '/images/catalog/categories/electrical-appliances.jpg', 'description' => 'کتری، پنکه، اتو و سایر وسایل برقی خانه'],
            ['name' => 'پوشاک', 'slug' => 'clothing', 'image' => '/images/catalog/categories/clothing.jpg', 'description' => 'لباس مردانه، زنانه و اطفال با کیفیت خوب'],
            ['name' => 'بخش اطفال', 'slug' => 'kids', 'image' => '/images/catalog/categories/kids.jpg', 'description' => 'لباس، اسباب‌بازی و لوازم مورد ضرورت اطفال'],
            ['name' => 'میوه خشک', 'slug' => 'dried-fruit', 'image' => '/images/catalog/categories/dried-fruit.jpg', 'description' => 'توت، انجیر و آلوچه خشک با کیفیت خوب'],
            ['name' => 'تحایف و هدیه ها', 'slug' => 'gifts', 'image' => '/images/catalog/categories/gifts.jpg', 'description' => 'جعبه تحفه، عطر و اقلام مناسب برای هدیه دادن'],
            ['name' => 'خشکبار', 'slug' => 'nuts', 'image' => '/images/catalog/categories/nuts.jpg', 'description' => 'بادام، پسته و چهارمغز تازه و باکیفیت'],
        ];

        foreach ($categories as $index => $category) {
            $attributes = [
                'name' => $category['name'],
                'slug' => $category['slug'],
                'description' => $category['description'],
                'image' => $category['image'],
                'parent_id' => null,
                'status' => 'enabled',
                'show_in_menu' => true,
                'sort_order' => $index + 1,
                'deleted_at' => null,
                'updated_at' => now(),
            ];

            $existingId = DB::table('categories')->where('slug', $category['slug'])->value('id');

            if ($existingId) {
                DB::table('categories')->where('id', $existingId)->update($attributes);
            } else {
                DB::table('categories')->insert($attributes + ['created_at' => now()]);
            }
        }
    }

    /**
     * Take the old demo categories out of the shop before the new ones go in.
     *
     * The list is deliberately explicit: only the categories this seeder itself
     * used to create are removed, so a category the owner made by hand is never
     * touched. "clothing" is left out on purpose -- the new catalogue re-uses
     * that slug, so it is updated in place instead of being deleted and re-made.
     * Any sub-category that pointed at a removed parent is left standing and
     * re-parented to the top level by the parent_id foreign key (nullOnDelete).
     */
    private function removeSupersededCategories(): void
    {
        $slugs = [
            'mobile-tablets',
            'laptops-computers',
            'home-appliances',
            'groceries',
            'beauty-health',
            'sports',
            'books-stationery',
        ];

        DB::table('categories')->whereIn('slug', $slugs)->delete();
    }

    /**
     * The brands the shop carries.
     */
    private function seedBrands(): void
    {
        $brands = [
            ['name' => 'سامسونگ', 'slug' => 'samsung', 'is_featured' => true],
            ['name' => 'اپل', 'slug' => 'apple', 'is_featured' => true],
            ['name' => 'هوآوی', 'slug' => 'huawei', 'is_featured' => true],
            ['name' => 'شیائومی', 'slug' => 'xiaomi', 'is_featured' => true],
            ['name' => 'سونی', 'slug' => 'sony', 'is_featured' => false],
            ['name' => 'ال‌جی', 'slug' => 'lg', 'is_featured' => false],
            ['name' => 'فیلیپس', 'slug' => 'philips', 'is_featured' => false],
            ['name' => 'نایکی', 'slug' => 'nike', 'is_featured' => false],
        ];

        foreach ($brands as $brand) {
            DB::table('brands')->updateOrInsert(
                ['slug' => $brand['slug']],
                [
                    'name' => $brand['name'],
                    'slug' => $brand['slug'],
                    'is_featured' => $brand['is_featured'],
                    'status' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }

    /**
     * The catalogue. Prices are in AFN, the store's base currency.
     */
    private function seedProducts(): void
    {
        $this->removeSupersededProducts();

        // Every product carries its own photo, keyed by slug and shipped inside
        // the app (public/images/catalog/products/<slug>.jpg). Afghan networks
        // often cannot reach outside image hosts, which left demo products blank,
        // so nothing here points at an external site. A leading "/" tells the
        // image model to serve the file straight from public/.
        $products = [
            ['name' => 'برنج باسمتی ۵ کیلویی', 'sku' => 'FOOD-RICE5', 'slug' => 'basmati-rice-5kg', 'category' => 'food-provisions', 'price' => 1450, 'featured' => true, 'qty' => 120, 'short' => 'برنج باسمتی — بسته ۵ کیلویی', 'desc' => 'برنج باسمتی خوش‌عطر و بلند، بسته‌بندی ۵ کیلوگرامی. مناسب مصرف روزمره خانواده.'],
            ['name' => 'روغن آفتابگردان ۵ لیتر', 'sku' => 'FOOD-OIL5', 'slug' => 'sunflower-oil-5l', 'category' => 'food-provisions', 'price' => 780, 'featured' => false, 'qty' => 150, 'short' => 'روغن آفتابگردان — ۵ لیتر', 'desc' => 'روغن آفتابگردان خالص، مناسب پخت‌وپز روزانه. بسته‌بندی ۵ لیتری.'],
            ['name' => 'آرد گندم ۱۰ کیلویی', 'sku' => 'FOOD-FLOUR10', 'slug' => 'wheat-flour-10kg', 'category' => 'food-provisions', 'price' => 620, 'featured' => false, 'qty' => 180, 'short' => 'آرد گندم — ۱۰ کیلوگرام', 'desc' => 'آرد گندم مرغوب و الک‌شده، مناسب پخت نان. بسته‌بندی ۱۰ کیلوگرامی.'],
            ['name' => 'صابون حمام', 'sku' => 'HYG-SOAP', 'slug' => 'bath-soap', 'category' => 'toiletries', 'price' => 90, 'featured' => false, 'qty' => 300, 'short' => 'صابون حمام گیاهی', 'desc' => 'صابون حمام با عصاره گیاهی، ملایم برای پوست و مناسب استفاده روزمره.'],
            ['name' => 'شامپو مو', 'sku' => 'HYG-SHAMPOO', 'slug' => 'hair-shampoo', 'category' => 'toiletries', 'price' => 260, 'featured' => true, 'qty' => 200, 'short' => 'شامپو مو — ۴۰۰ ملی‌لیتر', 'desc' => 'شامپو مو با فرمول ملایم، مناسب انواع مو. بسته‌بندی ۴۰۰ ملی‌لیتری.'],
            ['name' => 'کرم دست و صورت', 'sku' => 'HYG-CREAM', 'slug' => 'hand-face-cream', 'category' => 'toiletries', 'price' => 190, 'featured' => false, 'qty' => 220, 'short' => 'کرم دست و صورت', 'desc' => 'کرم مرطوب‌کننده دست و صورت با ویتامین E، مناسب پوست‌های خشک و حساس.'],
            ['name' => 'کتری برقی', 'sku' => 'ELE-KETTLE', 'slug' => 'electric-kettle', 'category' => 'electrical-appliances', 'price' => 1250, 'featured' => true, 'qty' => 60, 'short' => 'کتری برقی — ۱.۸ لیتر', 'desc' => 'کتری برقی با ظرفیت ۱.۸ لیتر، جوش سریع و محافظ خودکار. مناسب آشپزخانه.'],
            ['name' => 'پنکه سقفی', 'sku' => 'ELE-FAN', 'slug' => 'ceiling-fan', 'category' => 'electrical-appliances', 'price' => 2400, 'featured' => false, 'qty' => 35, 'short' => 'پنکه سقفی — سه سرعته', 'desc' => 'پنکه سقفی با سه سرعت، موتور کم‌صدا و مصرف برق پایین. مناسب فصل گرما.'],
            ['name' => 'اتو برقی', 'sku' => 'ELE-IRON', 'slug' => 'electric-iron', 'category' => 'electrical-appliances', 'price' => 1050, 'featured' => false, 'qty' => 50, 'short' => 'اتو برقی بخاردار', 'desc' => 'اتو برقی با کف نچسب و تنظیم حرارت، مناسب اتوی همه نوع پارچه.'],
            ['name' => 'پیراهن نخی مردانه', 'sku' => 'CLO-SHIRT', 'slug' => 'mens-cotton-shirt', 'category' => 'clothing', 'price' => 750, 'featured' => false, 'qty' => 120, 'short' => 'پیراهن نخی مردانه', 'desc' => 'پیراهن مردانه از پارچه نخی درجه اول، راحت و مناسب فصل گرما. در اندازه‌های متنوع.'],
            ['name' => 'شال زنانه', 'sku' => 'CLO-SHAWL', 'slug' => 'womens-shawl', 'category' => 'clothing', 'price' => 1200, 'featured' => true, 'qty' => 80, 'short' => 'شال زنانه', 'desc' => 'شال زنانه با پارچه نرم و رنگ‌های متنوع، مناسب استایل روزمره.'],
            ['name' => 'کاپشن زمستانی', 'sku' => 'CLO-JACKET', 'slug' => 'winter-jacket', 'category' => 'clothing', 'price' => 2600, 'featured' => false, 'qty' => 45, 'short' => 'کاپشن زمستانی', 'desc' => 'کاپشن زمستانی با آستر گرم و دوخت باکیفیت، مناسب فصل سرد.'],
            ['name' => 'لباس اطفال', 'sku' => 'KID-OUTFIT', 'slug' => 'kids-outfit', 'category' => 'kids', 'price' => 650, 'featured' => false, 'qty' => 90, 'short' => 'لباس اطفال', 'desc' => 'لباس اطفال از پارچه نرم و راحت، مناسب استفاده روزمره. در اندازه‌های مختلف.'],
            ['name' => 'اسباب‌بازی کودکان', 'sku' => 'KID-TOY', 'slug' => 'childrens-toy', 'category' => 'kids', 'price' => 450, 'featured' => false, 'qty' => 110, 'short' => 'اسباب‌بازی کودکان', 'desc' => 'اسباب‌بازی کودکان از مواد سالم، مناسب سرگرمی و تقویت خلاقیت اطفال.'],
            ['name' => 'پوشک اطفال', 'sku' => 'KID-DIAPERS', 'slug' => 'baby-diapers', 'category' => 'kids', 'price' => 380, 'featured' => true, 'qty' => 200, 'short' => 'پوشک اطفال', 'desc' => 'پوشک اطفال با جذب بالا و لایه نرم، مناسب استفاده شبانه‌روزی.'],
            ['name' => 'توت خشک', 'sku' => 'FRU-MULB', 'slug' => 'dried-mulberry', 'category' => 'dried-fruit', 'price' => 320, 'featured' => false, 'qty' => 90, 'short' => 'توت خشک — ۵۰۰ گرام', 'desc' => 'توت خشک طبیعی و شیرین، مناسب چای و پذیرایی. بسته‌بندی ۵۰۰ گرامی.'],
            ['name' => 'انجیر خشک', 'sku' => 'FRU-FIGS', 'slug' => 'dried-figs', 'category' => 'dried-fruit', 'price' => 480, 'featured' => true, 'qty' => 80, 'short' => 'انجیر خشک — ۵۰۰ گرام', 'desc' => 'انجیر خشک ممتاز با طعم شیرین و مغذی. بسته‌بندی ۵۰۰ گرامی.'],
            ['name' => 'آلوچه خشک', 'sku' => 'FRU-PLUM', 'slug' => 'dried-sour-plum', 'category' => 'dried-fruit', 'price' => 240, 'featured' => false, 'qty' => 100, 'short' => 'آلوچه خشک — ۵۰۰ گرام', 'desc' => 'آلوچه خشک با طعم ملس، مناسب پذیرایی و آشپزی. بسته‌بندی ۵۰۰ گرامی.'],
            ['name' => 'جعبه تحفه', 'sku' => 'GFT-BOX', 'slug' => 'gift-box', 'category' => 'gifts', 'price' => 1500, 'featured' => false, 'qty' => 40, 'short' => 'جعبه تحفه زیبا', 'desc' => 'جعبه تحفه با بسته‌بندی شیک، مناسب هدیه دادن در مناسبت‌ها.'],
            ['name' => 'ست عطر', 'sku' => 'GFT-PERFUME', 'slug' => 'perfume-set', 'category' => 'gifts', 'price' => 2200, 'featured' => true, 'qty' => 30, 'short' => 'ست عطر هدیه', 'desc' => 'ست عطر شامل بطری عطر و بسته‌بندی هدیه، مناسب تحفه دادن.'],
            ['name' => 'گلدان تزئینی', 'sku' => 'GFT-VASE', 'slug' => 'decorative-vase', 'category' => 'gifts', 'price' => 900, 'featured' => false, 'qty' => 55, 'short' => 'گلدان تزئینی', 'desc' => 'گلدان تزئینی با طراحی زیبا، مناسب دکوراسیون خانه و هدیه.'],
            ['name' => 'بادام', 'sku' => 'NUT-ALMOND', 'slug' => 'almonds', 'category' => 'nuts', 'price' => 1100, 'featured' => false, 'qty' => 70, 'short' => 'بادام — ۵۰۰ گرام', 'desc' => 'بادام باکیفیت و مغذی، مناسب پذیرایی. بسته‌بندی ۵۰۰ گرامی.'],
            ['name' => 'پسته', 'sku' => 'NUT-PISTA', 'slug' => 'pistachios', 'category' => 'nuts', 'price' => 1650, 'featured' => true, 'qty' => 60, 'short' => 'پسته — ۵۰۰ گرام', 'desc' => 'پسته تازه و خندان با طعم عالی، مناسب پذیرایی. بسته‌بندی ۵۰۰ گرامی.'],
            ['name' => 'چهارمغز', 'sku' => 'NUT-MIXED', 'slug' => 'mixed-nuts', 'category' => 'nuts', 'price' => 1350, 'featured' => false, 'qty' => 65, 'short' => 'چهارمغز — ۵۰۰ گرام', 'desc' => 'چهارمغز مخلوط از بادام، پسته، جوز و بادام زمینی. بسته‌بندی ۵۰۰ گرامی.'],
        ];

        foreach ($products as $product) {
            $categoryId = DB::table('categories')->where('slug', $product['category'])->value('id');
            $imagePath = '/images/catalog/products/'.$product['slug'].'.jpg';

            $existingId = DB::table('products')->where('sku', $product['sku'])->value('id');

            if ($existingId) {
                DB::table('products')->where('id', $existingId)->update([
                    'name' => $product['name'],
                    'slug' => $product['slug'],
                    'price' => $product['price'],
                    'description' => $product['desc'],
                    'short_description' => $product['short'],
                    'featured' => $product['featured'],
                    'quantity' => $product['qty'],
                    'deleted_at' => null,
                    'updated_at' => now(),
                ]);

                $productId = $existingId;
            } else {
                $productId = DB::table('products')->insertGetId([
                    'name' => $product['name'],
                    'sku' => $product['sku'],
                    'slug' => $product['slug'],
                    'type' => 'simple',
                    'price' => $product['price'],
                    'description' => $product['desc'],
                    'short_description' => $product['short'],
                    'status' => 'enabled',
                    'visibility' => 'both',
                    'featured' => $product['featured'],
                    'new' => true,
                    'quantity' => $product['qty'],
                    'manage_stock' => true,
                    'stock_status' => 'in_stock',
                    'min_quantity' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            if ($productId && $categoryId) {
                DB::table('category_product')->insertOrIgnore([
                    'category_id' => $categoryId,
                    'product_id' => $productId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            if ($productId) {
                $imageId = DB::table('product_images')
                    ->where('product_id', $productId)
                    ->orderBy('position')
                    ->value('id');

                if ($imageId) {
                    DB::table('product_images')->where('id', $imageId)->update([
                        'path' => $imagePath,
                        'thumbnail_path' => $imagePath,
                        'alt_text' => $product['name'],
                        'updated_at' => now(),
                    ]);
                } else {
                    $imageId = DB::table('product_images')->insertGetId([
                        'product_id' => $productId,
                        'path' => $imagePath,
                        'thumbnail_path' => $imagePath,
                        'alt_text' => $product['name'],
                        'position' => 1,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                DB::table('products')->where('id', $productId)->update(['main_image_id' => $imageId]);
            }
        }
    }

    /**
     * Take the old demo products out of the shop before the new catalogue goes in.
     *
     * Only the SKUs this seeder itself used to create are listed, so a product
     * the owner added by hand is never removed. Everything that hangs off a
     * product (its photos, its category links, its reviews, its stock history)
     * is deleted along with it by the database's cascade rules; only
     * credit-memo items refuse, which is why this is a deliberate hard delete on
     * a demo catalogue rather than a blanket wipe.
     */
    private function removeSupersededProducts(): void
    {
        $skus = [
            'PH-SAM-A55', 'PH-XIA-RN13P', 'PH-HUA-N12', 'TB-SAM-A9',
            'LP-ASU-VB15', 'LP-HP-PAV',
            'HA-SAM-F18', 'HA-LG-WM7', 'HA-PHI-COOK',
            'CL-M-SHIRT', 'CL-W-JACKET', 'CL-NK-SHOE',
            'GR-RICE', 'GR-OIL', 'GR-FLOUR',
            'BH-SOAP', 'BH-CREAM', 'BH-BP',
            'SP-BALL', 'SP-DUMBBELL', 'SP-TENT',
            'BK-STORIES', 'BK-PENS', 'BK-COPY',
        ];

        $ids = DB::table('products')->whereIn('sku', $skus)->pluck('id')->all();

        if ($ids === []) {
            return;
        }

        DB::table('products')->whereIn('id', $ids)->update(['main_image_id' => null]);
        DB::table('product_images')->whereIn('product_id', $ids)->delete();
        DB::table('category_product')->whereIn('product_id', $ids)->delete();
        DB::table('products')->whereIn('id', $ids)->delete();
    }

    /**
     * The services book the store takes bookings from, in Dari.
     */
    private function seedServiceCategories(): void
    {
        $categories = [
            ['name' => 'خدمات خانه', 'slug' => 'home-services', 'description' => 'پاککاری، شستوشو و کارهای روزمره خانه'],
            ['name' => 'خدمات تعمیرات', 'slug' => 'repair-services', 'description' => 'تعمیر برقی، لوله‌کشی، نجاری و سایر تعمیرات'],
            ['name' => 'خدمات زیبایی', 'slug' => 'beauty-services', 'description' => 'آرایش، اصلاح و مراقبت از زیبایی'],
            ['name' => 'خدمات نقلیه و باربری', 'slug' => 'transport-services', 'description' => 'اسباب‌کشی، باربری و انتقال اثاثیه'],
        ];

        foreach ($categories as $index => $category) {
            ServiceCategory::updateOrCreate(
                ['slug' => $category['slug']],
                [
                    'name' => $category['name'],
                    'description' => $category['description'],
                    'status' => 'enabled',
                    'show_in_menu' => true,
                    'sort_order' => $index + 1,
                ]
            );
        }
    }

    /**
     * The bookable services, each wired to a category.
     */
    private function seedServices(): void
    {
        $services = [
            ['name' => 'پاککاری کامل خانه', 'slug' => 'home-cleaning', 'category' => 'home-services', 'price' => 3000, 'unit' => 'per_job', 'minutes' => 180, 'featured' => true, 'short' => 'پاککاری کامل اتاق‌ها، آشپزخانه و تشناب', 'desc' => 'تیم پاککاری ما تمام اتاق‌ها، آشپزخانه و تشناب را به‌طور کامل پاک می‌کند. مواد پاک‌کننده همراه تیم است.', 'includes' => ['پاککاری اتاق‌ها و راهرو', 'پاککاری آشپزخانه', 'شستوشوی تشناب', 'گردگیری کامل'], 'excludes' => ['رنگ‌مالی دیوار', 'تعمیرات']],
            ['name' => 'شستوشوی فرش و قالین', 'slug' => 'carpet-washing', 'category' => 'home-services', 'price' => 2500, 'unit' => 'per_job', 'minutes' => 240, 'featured' => true, 'short' => 'شستوشوی قالین با مواد مخصوص', 'desc' => 'شستوشوی قالین و فرش با مواد مخصوص، خشک کردن و تحویل دوباره به خانه شما.', 'includes' => ['شستوشوی قالین', 'خشک کردن', 'بسته‌بندی'], 'excludes' => ['ترمیم قالین']],
            ['name' => 'رنگ‌مالی دیوار', 'slug' => 'wall-painting', 'category' => 'home-services', 'price' => 45, 'unit' => 'per_sqm', 'minutes' => 480, 'featured' => false, 'short' => 'رنگ‌مالی دیوار به ازای هر متر مربع', 'desc' => 'رنگ‌مالی دیوارها با رنگ باکیفیت. قیمت به ازای هر متر مربع قابل محاسبه است.', 'includes' => ['آماده‌سازی سطح', 'رنگ‌مالی'], 'excludes' => ['رنگ و مواد (به‌صورت جداگانه)']],
            ['name' => 'تعمیر برقی خانه', 'slug' => 'electrical-repair', 'category' => 'repair-services', 'price' => 1500, 'unit' => 'per_hour', 'minutes' => 60, 'featured' => false, 'short' => 'تعمیر سیستم برقی خانه', 'desc' => 'تشخیص و تعمیر مشکلات برقی خانه: پریز، سوییچ، فیوز و روشنایی.', 'includes' => ['تشخیص مشکل', 'تعمیرات', 'تست نهایی'], 'excludes' => ['خرید قطعات یدکی']],
            ['name' => 'لوله‌کشی و تنظیم تانک آب', 'slug' => 'plumbing-water-tank', 'category' => 'repair-services', 'price' => 2000, 'unit' => 'per_job', 'minutes' => 120, 'featured' => false, 'short' => 'لوله‌کشی و تنظیم تانک آب', 'desc' => 'تعمیر لوله‌کشی، باز کردن گرفتگی و تنظیم و پاککاری تانک آب.', 'includes' => ['تعمیر لوله', 'پاککاری تانک', 'کنترل فشار آب'], 'excludes' => ['خرید لوله و اتصالات']],
            ['name' => 'تعمیر موبایل و تبلت', 'slug' => 'mobile-repair', 'category' => 'repair-services', 'price' => 1200, 'unit' => 'per_job', 'minutes' => 90, 'featured' => true, 'short' => 'تعمیر موبایل و تبلت در محل', 'desc' => 'تعمیر نمایشگر، بتری، شارژ و سایر مشکلات موبایل و تبلت.', 'includes' => ['تشخیص', 'تعمیر', 'ضمانت ۳۰ روزه'], 'excludes' => ['خرید صفحه یا بتری نو']],
            ['name' => 'نجاری و درودگری', 'slug' => 'carpentry', 'category' => 'repair-services', 'price' => 1800, 'unit' => 'per_hour', 'minutes' => 120, 'featured' => false, 'short' => 'کارهای نجاری و درودگری', 'desc' => 'تعمیر درها، کمدها و ساخت قطعات چوبی مطابق اندازه شما.', 'includes' => ['اندازه‌گیری', 'ساخت و نصب', 'پاککاری محل'], 'excludes' => ['خرید چوب']],
            ['name' => 'اصلاح و آرایش عروس', 'slug' => 'bridal-makeup', 'category' => 'beauty-services', 'price' => 8000, 'unit' => 'per_job', 'minutes' => 180, 'featured' => true, 'short' => 'پکیج کامل آرایش عروس', 'desc' => 'آرایش و اصلاح کامل عروس توسط متخصصان، شامل مشوره قبل از مراسم.', 'includes' => ['آرایش صورت', 'بندی مو', 'مشوره'], 'excludes' => ['کرایه لباس']],
            ['name' => 'کوتاهی مو (آقایان)', 'slug' => 'haircut-men', 'category' => 'beauty-services', 'price' => 300, 'unit' => 'per_job', 'minutes' => 30, 'featured' => false, 'short' => 'کوتاهی موی آقایان', 'desc' => 'کوتاهی مو با استفاده از وسایل بهداشتی و الگوی دلخواه شما.', 'includes' => ['کوتاهی مو', 'اصلاح صورت'], 'excludes' => ['رنگ و مواد']],
            ['name' => 'باربری و اسباب‌کشی', 'slug' => 'moving-service', 'category' => 'transport-services', 'price' => 5000, 'unit' => 'per_job', 'minutes' => 240, 'featured' => true, 'short' => 'اسباب‌کشی شهری', 'desc' => 'کارگر و موتر باربری برای انتقال اثاثیه شما در داخل شهر.', 'includes' => ['کارگرهای ماهر', 'موتر باربری', 'بسته‌بندی اساسی'], 'excludes' => ['بیمه اثاثیه قیمتی']],
        ];

        foreach ($services as $index => $row) {
            $category = ServiceCategory::where('slug', $row['category'])->first();

            Service::updateOrCreate(
                ['slug' => $row['slug']],
                [
                    'service_category_id' => $category?->id,
                    'name' => $row['name'],
                    'short_description' => $row['short'],
                    'description' => $row['desc'],
                    'includes' => $row['includes'],
                    'excludes' => $row['excludes'],
                    'price' => $row['price'],
                    'price_unit' => $row['unit'],
                    'duration_minutes' => $row['minutes'],
                    'service_area' => 'کابل، هرات، مزار شریف، جلال‌آباد',
                    'status' => 'enabled',
                    'featured' => $row['featured'],
                    'booking_enabled' => true,
                    'sort_order' => $index + 1,
                ]
            );
        }
    }

    /**
     * The store's pages. "تماس با ما" carries the contact form, because the theme
     * looks for a page whose address contains "contact".
     */
    private function seedPages(): void
    {
        $pages = [
            ['title' => 'درباره ما', 'url_key' => 'about-us', 'content' => '<h1>درباره عصر آسان</h1><p>عصر آسان فروشگاه آنلاین شما در افغانستان است. هدف ما این است که خرید وسائل مورد ضرورت را برای شما ساده، مطمئن و سریع بسازیم.</p>'],
            ['title' => 'تماس با ما', 'url_key' => 'contact-us', 'content' => '<h1>تماس با ما</h1><p>اگر پرسشی دارید، از طریق فورم زیر پیام بفرستید یا ما را در واتس‌اپ پیام کنید. ما در جریان یک روز کاری پاسخ می‌دهیم.</p>'],
            ['title' => 'شرایط و ضوابط', 'url_key' => 'terms-and-conditions', 'content' => '<h1>شرایط و ضوابط</h1><p>استفاده از خدمات عصر آسان به معنی پذیرش شرایط زیر است. لطفاً پیش از خرید مطالعه کنید.</p>'],
            ['title' => 'سیاست بازگشت کالا', 'url_key' => 'returns-policy', 'content' => '<h1>سیاست بازگشت کالا</h1><p>شما می‌توانید تا ۷ روز پس از دریافت کالا، در صورت سالم بودن بسته‌بندی، آن را برگردانید.</p>'],
            ['title' => 'سیاست حریم خصوصی', 'url_key' => 'privacy-policy', 'content' => '<h1>سیاست حریم خصوصی</h1><p>ما معلومات شخصی شما را محفوظ نگه می‌داریم و آن را با کسی به اشتراک نمی‌گذاریم.</p>'],
        ];

        foreach ($pages as $page) {
            DB::table('pages')->updateOrInsert(
                ['url_key' => $page['url_key']],
                [
                    'title' => $page['title'],
                    'url_key' => $page['url_key'],
                    'content' => $page['content'],
                    'status' => 'published',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }

    /**
     * Front-page content blocks, in Dari.
     */
    private function seedBlocks(): void
    {
        $blocks = [
            ['identifier' => 'persian-hero-banner', 'title' => 'بنر اصلی', 'content' => '<div>خرید آسان و مطمئن از خانه — تحویل سریع در سراسر افغانستان</div>'],
            ['identifier' => 'persian-footer-info', 'title' => 'معلومات پاصفحه', 'content' => '<p>عصر آسان — همراه شما برای خرید راحت.</p>'],
        ];

        foreach ($blocks as $block) {
            DB::table('blocks')->updateOrInsert(
                ['identifier' => $block['identifier']],
                [
                    'title' => $block['title'],
                    'content' => $block['content'],
                    'status' => 'active',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }

    /**
     * Two accounts to try the store with: one owner, one shopper.
     *
     * The shopper also gets a customer record so order/report screens and the
     * sales demo have somebody to sell to.
     */
    private function seedDemoAccounts(): void
    {
        $password = env('DEMO_ACCOUNT_PASSWORD', 'Asaan@2026');

        User::updateOrCreate(
            ['email' => 'demo@asaan.af'],
            [
                'name' => 'مدیر فروشگاه (دیمو)',
                'password' => Hash::make($password),
                'role' => 'admin',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        $shopper = User::updateOrCreate(
            ['email' => 'shopper@asaan.af'],
            [
                'name' => 'احمد رحیمی',
                'password' => Hash::make($password),
                'role' => 'customer',
                'is_active' => true,
                'email_verified_at' => now(),
            ]
        );

        $this->ensureCustomerRecord($shopper, $shopper->name, '+93 700 111 222');

        // A couple more buyers so the customer list and the sales reports are not
        // a table of one.
        foreach ([
            ['email' => 'fatima@asaan.af', 'name' => 'فاطمه نوری', 'phone' => '+93 700 333 444'],
            ['email' => 'karim@asaan.af', 'name' => 'کریم نظری', 'phone' => '+93 700 555 666'],
        ] as $person) {
            $buyer = User::updateOrCreate(
                ['email' => $person['email']],
                [
                    'name' => $person['name'],
                    'password' => Hash::make($password),
                    'role' => 'customer',
                    'is_active' => true,
                    'email_verified_at' => now(),
                ]
            );

            $this->ensureCustomerRecord($buyer, $buyer->name, $person['phone']);
        }

        $this->command?->info('Demo accounts ready.');
        $this->command?->info('Owner:   demo@asaan.af / '.$password);
        $this->command?->info('Shopper: shopper@asaan.af / '.$password);
    }

    /**
     * Give a user a matching customer row, with their name split into first and
     * last. Safe to run again on a shop that already has the customer.
     */
    private function ensureCustomerRecord(User $user, string $name, ?string $phone = null): void
    {
        $firstName = Str::before($name, ' ');
        $lastName = Str::contains($name, ' ') ? Str::after($name, ' ') : '';

        DB::table('customers')->updateOrInsert(
            ['user_id' => $user->id],
            [
                'first_name' => $firstName,
                'last_name' => $lastName,
                'email' => $user->email,
                'phone' => $phone,
                'is_active' => true,
                'is_guest' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ]
        );
    }
}
