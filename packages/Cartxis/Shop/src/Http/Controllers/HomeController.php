<?php

namespace Cartxis\Shop\Http\Controllers;

use Cartxis\Core\Models\Theme;
use Cartxis\Core\Services\SettingService;
use Cartxis\Core\Services\ThemeViewResolver;
use Cartxis\Shop\Services\HomeService;
use Cartxis\UIEditor\Services\LayoutService;
use Inertia\Inertia;
use Inertia\Response;

class HomeController extends Controller
{
    /**
     * @var HomeService
     */
    protected $homeService;

    /**
     * @var ThemeViewResolver
     */
    protected $themeResolver;

    /**
     * @var SettingService
     */
    protected $settingService;

    /**
     * @var LayoutService
     */
    protected $layoutService;

    /**
     * Create a new controller instance.
     */
    public function __construct(HomeService $homeService, ThemeViewResolver $themeResolver, SettingService $settingService, LayoutService $layoutService)
    {
        $this->homeService = $homeService;
        $this->themeResolver = $themeResolver;
        $this->settingService = $settingService;
        $this->layoutService = $layoutService;
    }

    /**
     * Display the homepage.
     *
     * @return Response
     */
    public function index()
    {
        $data = $this->homeService->getHomepageData();
        $homepageLayout = $this->usesNativeHomepage()
            ? null
            : $this->layoutService->getPublishedHomepage();

        // Use ThemeViewResolver to get correct view path
        return Inertia::render($this->themeResolver->resolve('Home/Index'), [
            // 'theme' prop is shared via HandleInertiaRequests middleware (flattened settings)
            'featuredProducts' => $data['featured_products'],
            'heroProducts' => $data['hero_products'] ?? [],
            'offerProducts' => $data['offer_products'] ?? [],
            'bannerProduct' => $data['banner_product'] ?? null,
            'featuredCategories' => $data['categories'], // Renamed for clarity
            'newProducts' => $data['new_products'],
            // Note: no 'categories' override here on purpose. The header
            // reads the shared category list from the middleware, which is
            // built live. Passing the cached homepage list instead would make
            // the header show stale categories on the busiest page of the
            // shop (links that were renamed or deleted still listed, new ones
            // missing until the homepage cache expired).
            'cmsBlocks' => $data['blocks'] ?? [],
            'layoutData' => $homepageLayout?->layout_data,
            'siteConfig' => [
                'name' => $this->settingService->get('site_name') ?? config('branding.name', 'Akbari Development Group'),
                'url' => config('app.url'),
                'description' => $this->settingService->get('site_tagline') ?? config('branding.description'),
                'logo' => $this->settingService->get('site_logo') ?? config('branding.logo'),
                'favicon' => $this->settingService->get('site_favicon') ?? config('branding.favicon'),
            ],
            'seo' => [
                'title' => config('app.name').' - '.trans('shop::shop.homepage.title'),
                'description' => 'Welcome to our online store',
                'keywords' => 'ecommerce, shop, products',
            ],
        ]);
    }

    protected function usesNativeHomepage(): bool
    {
        $theme = Theme::active();

        if (! $theme) {
            return false;
        }

        return (bool) ($theme->getConfig()['native_homepage'] ?? false);
    }
}
