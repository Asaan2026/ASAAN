<?php

namespace Cartxis\API\Http\Controllers\V1;

use App\Http\Controllers\Controller;
use Cartxis\API\Helpers\ApiResponse;
use Cartxis\API\Http\Resources\OrderResource;
use Cartxis\Sales\Services\OrderService;
use Cartxis\Shop\Models\Order;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    /**
     * Get customer orders.
     */
    public function index(Request $request)
    {
        $perPage = min($request->get('per_page', 20), config('cartxis-api.pagination.max_per_page'));

        $query = Order::where('user_id', $request->user()->id)
            ->with(['items.product', 'shippingAddress', 'billingAddress']);

        // Filter by status
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $orders = $query->latest()->paginate($perPage);

        return ApiResponse::paginated(
            $orders->through(fn ($order) => new OrderResource($order)),
            'Orders retrieved successfully'
        );
    }

    /**
     * Get single order details.
     */
    public function show(Request $request, $id)
    {
        $order = Order::with([
            'items.product.images',
            'shippingAddress',
            'billingAddress',
            'shipments',
            'invoices',
        ])
            ->where('user_id', $request->user()->id)
            ->find($id);

        if (! $order) {
            return ApiResponse::notFound('Order not found', 'ORDER_NOT_FOUND');
        }

        return ApiResponse::success(
            new OrderResource($order),
            'Order details retrieved successfully'
        );
    }

    /**
     * Cancel order.
     */
    public function cancel(Request $request, $id, OrderService $orderService)
    {
        $order = Order::with(['items.product'])
            ->where('user_id', $request->user()->id)
            ->find($id);

        if (! $order) {
            return ApiResponse::notFound('Order not found', 'ORDER_NOT_FOUND');
        }

        // The same window the storefront and the app are told about through
        // the order's can_cancel flag. Keep the three in step.
        if (! in_array($order->status, ['pending', 'processing'])) {
            return ApiResponse::error(
                'Order cannot be cancelled',
                null,
                400,
                'ORDER_CANNOT_BE_CANCELLED'
            );
        }

        $reason = 'Cancelled by the customer';

        // Stock is only taken off the shelf when an order reaches processing
        // (see OrderService::handleStatusChangeActions), so a pending order has
        // nothing to give back. Putting it back anyway would invent stock the
        // shop does not have, which is why this is not left to the method's
        // default of always restoring.
        $stockWasTaken = $order->status === Order::STATUS_PROCESSING;

        // One shared cancellation path, the same one the dashboard uses: it
        // puts the stock back, writes the order history the customer can see,
        // sends the cancellation email and tells the admins -- all inside a
        // transaction, so a failure part way through leaves nothing half done.
        if (! $orderService->cancelOrder($order, $reason, $stockWasTaken)) {
            return ApiResponse::error(
                'We could not cancel this order. Please try again.',
                null,
                500,
                'ORDER_CANCEL_FAILED'
            );
        }

        // Money comes back only once the order really is cancelled.
        $refund = $orderService->refundCancelledOrder($order->refresh(), $reason);

        $message = match ($refund['state']) {
            'refunded' => 'Order cancelled. Your refund is on its way back to you.',
            'pending' => 'Order cancelled. The shop will arrange your refund.',
            default => 'Order cancelled successfully',
        };

        $order->load([
            'items.product.images',
            'shippingAddress',
            'billingAddress',
            'shipments',
        ]);

        return ApiResponse::success(
            new OrderResource($order),
            $message
        );
    }

    /**
     * Get order invoice.
     */
    public function invoice(Request $request, $id)
    {
        $order = Order::with(['items.product', 'shippingAddress', 'billingAddress'])
            ->where('user_id', $request->user()->id)
            ->find($id);

        if (! $order) {
            return ApiResponse::notFound('Order not found', 'ORDER_NOT_FOUND');
        }

        // TODO: Generate PDF invoice
        // For now, return invoice data

        return ApiResponse::success([
            'order' => new OrderResource($order),
            'invoice_url' => route('api.orders.invoice.pdf', $order->id),
        ], 'Invoice retrieved successfully');
    }

    /**
     * Track order.
     */
    public function track(Request $request, $id)
    {
        $order = Order::with(['shipments.trackingInfo'])
            ->where('user_id', $request->user()->id)
            ->find($id);

        if (! $order) {
            return ApiResponse::notFound('Order not found', 'ORDER_NOT_FOUND');
        }

        $trackingInfo = [];

        if ($order->shipments->isNotEmpty()) {
            $shipment = $order->shipments->first();
            $trackingInfo = [
                'tracking_number' => $shipment->tracking_number ?? null,
                'carrier' => $shipment->carrier ?? null,
                'status' => $shipment->status ?? null,
                'shipped_at' => $shipment->shipped_at?->toIso8601String(),
                'estimated_delivery' => $shipment->estimated_delivery?->toIso8601String(),
                'tracking_url' => $shipment->tracking_url ?? null,
            ];
        }

        return ApiResponse::success([
            'order_id' => $order->id,
            'order_number' => $order->order_number,
            'status' => $order->status,
            'tracking' => $trackingInfo,
        ], 'Order tracking information retrieved');
    }
}
