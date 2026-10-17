<?php

namespace Cartxis\Shop\Repositories;

use Cartxis\Product\Models\Category;
use Cartxis\Shop\Contracts\CategoryRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

class CategoryRepository extends ShopRepository implements CategoryRepositoryInterface
{
    /**
     * Specify Model class name.
     *
     * @return string
     */
    public function model()
    {
        return Category::class;
    }

    /**
     * Get root categories.
     *
     * @return Collection
     */
    public function getRootCategories()
    {
        return $this->model
            ->whereNull('parent_id')
            ->where('status', 'enabled')
            ->orderBy('sort_order')
            ->get();
    }

    /**
     * Get root categories for the storefront header menu.
     *
     * @return Collection
     */
    public function getMenuCategories()
    {
        return $this->model
            ->whereNull('parent_id')
            ->where('status', 'enabled')
            ->where('show_in_menu', true)
            ->orderBy('sort_order')
            ->get();
    }

    /**
     * Get category by slug.
     *
     * @param  string  $slug
     * @return Model|null
     */
    public function findBySlug($slug)
    {
        return $this->model
            ->where('slug', $slug)
            ->where('status', 'enabled')
            ->first();
    }

    /**
     * Get category with products.
     *
     * @param  int  $id
     * @return Model|null
     */
    public function getWithProducts($id)
    {
        return $this->model
            ->with(['products' => function ($query) {
                $query->where('status', 'enabled');
            }])
            ->find($id);
    }

    /**
     * Get category children.
     *
     * @param  int  $parentId
     * @return Collection
     */
    public function getChildren($parentId)
    {
        return $this->model
            ->where('parent_id', $parentId)
            ->where('status', 'enabled')
            ->orderBy('sort_order')
            ->get();
    }

    /**
     * Get all active categories.
     *
     * @return Collection
     */
    public function getActiveCategories()
    {
        return $this->model
            ->where('status', 'enabled')
            ->orderBy('sort_order')
            ->get();
    }
}
