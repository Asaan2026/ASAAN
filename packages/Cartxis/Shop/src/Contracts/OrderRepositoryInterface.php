<?php

namespace Cartxis\Shop\Contracts;

use Cartxis\Shop\Models\Order;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

interface OrderRepositoryInterface extends ShopRepositoryInterface
{
    /**
     * Find an order by order number.
     *
     * @return Order|null
     */
    public function findByOrderNumber(string $orderNumber);

    /**
     * Get orders for a specific user.
     *
     * @return LengthAwarePaginator
     */
    public function getByUser(int $userId, int $perPage = 10);

    /**
     * Get orders with a specific status.
     *
     * @return LengthAwarePaginator
     */
    public function getByStatus(string $status, int $perPage = 10);

    /**
     * Update order status.
     */
    public function updateStatus(int $orderId, string $status): bool;

    /**
     * Update payment status.
     */
    public function updatePaymentStatus(int $orderId, string $status): bool;

    /**
     * Get order with all relationships (items, addresses, user).
     *
     * @return Order|null
     */
    public function getWithRelations(int $orderId);

    /**
     * Get recent orders.
     *
     * @return Collection
     */
    public function getRecent(int $limit = 10);

    /**
     * Get total order count for a user.
     */
    public function getUserOrderCount(int $userId): int;

    /**
     * Get total revenue for a user.
     */
    public function getUserTotalRevenue(int $userId): float;

    /**
     * Search orders by order number, email, or name.
     *
     * @return LengthAwarePaginator
     */
    public function search(string $query, int $perPage = 10);

    /**
     * Get orders within a date range.
     *
     * @return LengthAwarePaginator
     */
    public function getByDateRange(string $startDate, string $endDate, int $perPage = 10);

    /**
     * Cancel an order.
     */
    public function cancel(int $orderId): bool;

    /**
     * Mark order as paid.
     */
    public function markAsPaid(int $orderId): bool;
}
