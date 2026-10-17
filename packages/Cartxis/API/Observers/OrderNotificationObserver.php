<?php

namespace Cartxis\API\Observers;

use Cartxis\API\Services\CustomerNotificationService;
use Cartxis\Shop\Models\Order;

/**
 * Turns an order's life into a notification for the customer who placed it.
 *
 * It hangs off the model rather than the admin screen, so an order changed from
 * the admin, from the API, from an import or from artisan all notify the same
 * way. A rule that lived in one screen would be a rule the other paths skip.
 */
class OrderNotificationObserver
{
    public function __construct(protected CustomerNotificationService $notifications) {}

    public function created(Order $order): void
    {
        $this->notifications->notifyOrderStatus($order);
    }

    public function updated(Order $order): void
    {
        if (! $order->wasChanged('status')) {
            return;
        }

        $this->notifications->notifyOrderStatus($order, $order->getOriginal('status'));
    }
}
