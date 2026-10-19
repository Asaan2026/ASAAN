<?php

namespace Cartxis\API\Services;

use App\Models\User;
use Cartxis\API\Models\CustomerNotification;
use Cartxis\API\Services\Push\PushSender;
use Cartxis\Core\Services\SettingService;
use Cartxis\Shop\Models\Order;

/**
 * Creates a customer's in-app notification, and asks the push sender to mirror
 * it onto the phone.
 *
 * This is the one place a notification is born. Order status changes and admin
 * announcements both come through here, so the wording and the fields the app
 * reads stay the same no matter what triggered them.
 */
class CustomerNotificationService
{
    public function __construct(
        protected PushSender $push,
        protected SettingService $settings,
    ) {}

    /**
     * @param  array<string, mixed>  $data  Extra values the app uses to open the
     *                                      right screen, e.g. ['order_number' => '...'].
     */
    public function notify(
        User $user,
        string $type,
        string $title,
        string $body,
        array $data = [],
    ): CustomerNotification {
        $notification = CustomerNotification::create([
            'user_id' => $user->id,
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data ?: null,
        ]);

        $this->pushToDevices($user, $notification);

        return $notification;
    }

    /**
     * Announce an order's new status to the person who placed it.
     *
     * Silent when the order has no signed-in user (a guest checkout) -- there is
     * no app account to notify.
     */
    public function notifyOrderStatus(Order $order, ?string $previousStatus = null): ?CustomerNotification
    {
        $user = $order->user;

        if (! $user) {
            return null;
        }

        if ($previousStatus !== null && $previousStatus === $order->status) {
            return null;
        }

        // The owner can turn order updates off from the dashboard without
        // touching any other kind of notification.
        if (! (bool) $this->settings->get('notifications_customer_order_updates', true)) {
            return null;
        }

        [$title, $body] = $this->orderStatusMessage($order);

        return $this->notify($user, 'order', $title, $body, [
            'order_id' => $order->id,
            'order_number' => $order->order_number,
            'status' => $order->status,
        ]);
    }

    /**
     * Send one notification to every phone this customer has signed in on.
     *
     * The dashboard's push switch only silences the phone: the in-app row is
     * already written by the time we get here, so the bell in the app keeps
     * working while push is off.
     */
    protected function pushToDevices(User $user, CustomerNotification $notification): void
    {
        if (! $this->push->isConfigured()) {
            return;
        }

        if (! (bool) $this->settings->get('notifications_push_enabled', true)) {
            return;
        }

        foreach ($user->deviceTokens()->get() as $device) {
            $this->push->send(
                $device->token,
                $notification->title,
                $notification->body,
                array_merge($notification->data ?? [], ['notification_id' => $notification->id]),
                $notification->type,
            );
        }
    }

    /**
     * The two lines a customer reads for an order. Written once here so the bell
     * list and the push say the same thing.
     *
     * @return array{0: string, 1: string}
     */
    protected function orderStatusMessage(Order $order): array
    {
        $number = $order->order_number;

        return match ($order->status) {
            Order::STATUS_PENDING => [
                'Order received',
                "We have received order {$number}. It is waiting to be processed.",
            ],
            Order::STATUS_PROCESSING => [
                'Your order is being prepared',
                "Order {$number} is now being processed.",
            ],
            Order::STATUS_COMPLETED => [
                'Order completed',
                "Order {$number} has been completed. Thank you for shopping with us.",
            ],
            Order::STATUS_CANCELLED => [
                'Order cancelled',
                "Order {$number} has been cancelled.",
            ],
            Order::STATUS_REFUNDED => [
                'Order refunded',
                "Order {$number} has been refunded.",
            ],
            Order::STATUS_FAILED => [
                'Payment failed',
                "The payment for order {$number} did not go through.",
            ],
            default => [
                'Order update',
                "Order {$number} has a new status.",
            ],
        };
    }
}
