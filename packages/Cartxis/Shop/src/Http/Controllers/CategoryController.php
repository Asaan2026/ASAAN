<?php

namespace Cartxis\Shop\Http\Controllers;

use Cartxis\Core\Services\ThemeViewResolver;
use Cartxis\Shop\Services\CategoryService;
use Cartxis\Shop\Services\ProductService;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class CategoryController extends Controller
{
    /**
     * @var CategoryService
     */
    protected $categoryService;

    /**
     * @var ProductService
     */
    protected $productService;

    /**
     * @var ThemeViewResolver
     */
    protected $themeResolver;

    /**
     * Create a new controller instance.
     */
    public function __construct(
        CategoryService $categoryService,
        ProductService $productService,
        ThemeViewResolver $themeResolver
    ) {
        $this->categoryService = $categoryService;
        $this->productService = $productService;
        $this->themeResolver = $themeResolver;
    }

    /**
     * Display category page with products.
     *
     * @param  string  $slug
     * @return Response
     */
    public function show($slug, Request $request)
    {
        $category = $this->categoryService->getCategoryBySlug($slug);

        if (! $category) {
            abort(404, 'Category not found');
        }

        $category->load([
            'children' => fn ($query) => $query->where('status', 'enabled'),
        ]);

        $filters = [
            'per_page' => $request->input('per_page', config('shop.listing.products_per_page', 12)),
            'sort' => $request->input('sort', config('shop.listing.default_sort', 'position')),
        ];

        $products = $this->productService->getProductsByCategory($category->id, $filters);

        return Inertia::render($this->themeResolver->resolve('Category/Show'), [
            'category' => $category,
            'products' => $products,
            'filters' => $filters,
            'seo' => [
                'title' => $category->meta_title ?? $category->name,
                'description' => $category->meta_description ?? substr(strip_tags($category->description ?? ''), 0, 160),
                'keywords' => $category->meta_keywords ?? '',
            ],
        ]);
    }
}
