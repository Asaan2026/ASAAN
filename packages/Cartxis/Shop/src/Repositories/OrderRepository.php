<?php

namespace Cartxis\Shop\Repositories;

use Cartxis\Shop\Contracts\OrderRepositoryInterface;
use Cartxis\Shop\Models\Order;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class OrderRepository extends ShopRepository implements OrderRepositoryInterface
{
    /**
     * Specify Model class name.
     *
     * @return string
     */
    public function model()
    {
        return Order::class;
    }

    /**
     * Find an order by order number.
     *
     * @return Order|null
     */
    public function findByOrderNumber(string $orderNumber)
    {
        return $this->model->where('order_number', $orderNumber)->first();
    }

    /**
     * Get orders for a specific user.
     *
     * @return LengthAwarePaginator
     */
    public function getByUser(int $userId, int $perPage = 10)
    {
        return $this->model
            ->where('user_id', $userId)
            ->with(['items.product', 'addresses'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);
    }

    /**
     * Get orders with a specific status.
     *
     * @return LengthAwarePaginator
     */
    public function getByStatus(string $status, int $perPage = 10)
    {
        return $this->model
            ->where('status', $status)
            ->with(['user', 'items'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);
    }

    /**
     * Update order status.
     */
    public function updateStatus(int $orderId, string $status): bool
    {
        $order = $this->find($orderId);

        if (! $order) {
            return false;
        }

        return $order->update(['status' => $status]);
    }

    /**
     * Update payment status.
     */
    public function updatePaymentStatus(int $orderId, string $status): bool
    {
        $order = $this->find($orderId);

        if (! $order) {
            return false;
        }

        return $order->update(['payment_status' => $status]);
    }

    /**
     * Get order with all relationships (items, addresses, user).
     *
     * @return Order|null
     */
    public function getWithRelations(int $orderId)
    {
        return $this->model
            ->with([
                'user',
                'items.product.mainImage',
                'addresses',
            ])
            ->find($orderId);
    }

    /**
     * Get recent orders.
     *
     * @return Collection
     */
    public function getRecent(int $limit = 10)
    {
        return $this->model
            ->with(['user', 'items'])
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();
    }

    /**
     * Get total order count for a user.
     */
    public function getUserOrderCount(int $userId): int
    {
        return $this->model
            ->where('user_id', $userId)
            ->count();
    }

    /**
     * Get total revenue for a user.
     */
    public function getUserTotalRevenue(int $userId): float
    {
        return (float) $this->model
            ->where('user_id', $userId)
            ->where('payment_status', Order::PAYMENT_PAID)
            ->sum('total');
    }

    /**
     * Search orders by order number, email, or name.
     *
     * @return LengthAwarePaginator
     */
    public function search(string $query, int $perPage = 10)
    {
        return $this->model
            ->where(function ($q) use ($query) {
                $q->where('order_number', 'LIKE', "%{$query}%")
                    ->orWhere('customer_email', 'LIKE', "%{$query}%")
                    ->orWhereHas('user', function ($userQuery) use ($query) {
                        $userQuery->where('name', 'LIKE', "%{$query}%")
                            ->orWhere('email', 'LIKE', "%{$query}%");
                    });
            })
            ->with(['user', 'items'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);
    }

    /**
     * Get orders within a date range.
     *
     * @return LengthAwarePaginator
     */
    public function getByDateRange(string $startDate, string $endDate, int $perPage = 10)
    {
        return $this->model
            ->whereBetween('created_at', [$startDate, $endDate])
            ->with(['user', 'items'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);
    }

    /**
     * Cancel an order.
     */
    public function cancel(int $orderId): bool
    {
        $order = $this->find($orderId);

        if (! $order || ! $order->canBeCancelled()) {
            return false;
        }

        return $order->update(['status' => Order::STATUS_CANCELLED]);
    }

    /**
     * Mark order as paid.
     */
    public function markAsPaid(int $orderId): bool
    {
        $order = $this->find($orderId);

        if (! $order) {
            return false;
        }

        return $order->update([
            'payment_status' => Order::PAYMENT_PAID,
            'status' => Order::STATUS_PROCESSING,
        ]);
    }
}
