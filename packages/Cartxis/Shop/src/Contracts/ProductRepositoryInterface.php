<?php

namespace Cartxis\Shop\Contracts;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Model;

interface ProductRepositoryInterface extends ShopRepositoryInterface
{
    /**
     * Get featured products.
     *
     * @param  int  $limit
     * @return Collection
     */
    public function getFeaturedProducts($limit = 12);

    /**
     * Get new products.
     *
     * @param  int  $limit
     * @return Collection
     */
    public function getNewProducts($limit = 12);

    /**
     * Get products currently on sale.
     *
     * @param  int  $limit
     * @return Collection
     */
    public function getOnSaleProducts($limit = 12);

    /**
     * Resolve products by ID or slug, preserving reference order.
     *
     * @param  array<int, array{type: string, value: int|string}>  $references
     * @return Collection
     */
    public function resolveProductReferences(array $references);

    /**
     * Get product by slug.
     *
     * @param  string  $slug
     * @return Model|null
     */
    public function findBySlug($slug);

    /**
     * Get products by category.
     *
     * @param  int  $categoryId
     * @param  int  $perPage
     * @return LengthAwarePaginator
     */
    public function getByCategory($categoryId, $perPage = 12);

    /**
     * Search products.
     *
     * @param  string  $query
     * @param  int  $perPage
     * @return LengthAwarePaginator
     */
    public function search($query, $perPage = 12);

    /**
     * Get related products.
     *
     * @param  int  $productId
     * @param  int  $limit
     * @return Collection
     */
    public function getRelatedProducts($productId, $limit = 4);

    /**
     * Get product with reviews.
     *
     * @param  int  $id
     * @return Model|null
     */
    public function getWithReviews($id);
}
