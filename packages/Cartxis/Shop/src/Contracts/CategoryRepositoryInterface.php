<?php

namespace Cartxis\Shop\Contracts;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

interface CategoryRepositoryInterface extends ShopRepositoryInterface
{
    /**
     * Get root categories.
     *
     * @return Collection
     */
    public function getRootCategories();

    /**
     * Get root categories that belong in the storefront header menu.
     *
     * @return Collection
     */
    public function getMenuCategories();

    /**
     * Get category by slug.
     *
     * @param  string  $slug
     * @return Model|null
     */
    public function findBySlug($slug);

    /**
     * Get category with products.
     *
     * @param  int  $id
     * @return Model|null
     */
    public function getWithProducts($id);

    /**
     * Get category children.
     *
     * @param  int  $parentId
     * @return Collection
     */
    public function getChildren($parentId);

    /**
     * Get all active categories.
     *
     * @return Collection
     */
    public function getActiveCategories();
}
