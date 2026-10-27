<?php

use App\Models\User;
use Cartxis\Core\Services\PaymentGatewayManager;
use Cartxis\Product\Models\Product;
use Cartxis\Sales\Models\OrderHistory;
use Cartxis\Sales\Models\Transaction;
use Cartxis\Sales\Services\OrderService;
use Cartxis\Shop\Models\Order;
use Cartxis\Shop\Models\OrderItem;
use Illuminate\Support\Str;

/*
|--------------------------------------------------------------------------
| Cancelling your own order from the app
|--------------------------------------------------------------------------
|
| The endpoint used to do one thing: write "cancelled" on the order. It left
| two notes in the code saying the stock still had to go back and the money
| still had to be returned, which meant a customer could cancel a paid order
| and be left out of pocket while the goods stayed off the shelf.
|
| These tests hold the whole cancellation to account: who may cancel, what
| happens to the stock, and what happens to the money -- including when the
| money cannot be sent back automatically, which is the case for every cash
| order.
|
*/

function cancelTestUser(): User
{
    return User::create([
        'name' => 'Cancelling Customer',
        'email' => 'cancel-'.Str::random(6).'@example.test',
        'password' => bcrypt('password'),
    ]);
}

function cancelTestProduct(int $stock = 10): Product
{
    return Product::create([
        'name' => 'Green tea',
        'sku' => 'TEA-'.Str::random(5),
        'price' => 100,
        'quantity' => $stock,
        'status' => 'enabled',
        'type' => 'simple',
        'manage_stock' => true,
    ]);
}

function cancelTestOrder(
    User $user,
    Product $product,
    string $status = 'processing',
    string $paymentStatus = 'pending',
    string $paymentMethod = 'cod',
    int $quantity = 2,
    float $total = 200,
): Order {
    $order = Order::create([
        'user_id' => $user->id,
        'customer_email' => $user->email,
        'order_number' => 'ORD-'.strtoupper(Str::random(8)),
        'status' => $status,
        'payment_method' => $paymentMethod,
        'payment_status' => $paymentStatus,
        'subtotal' => $total,
        'total' => $total,
    ]);

    OrderItem::create([
        'order_id' => $order->id,
        'product_id' => $product->id,
        'product_sku' => $product->sku,
        'product_name' => $product->name,
        'quantity' => $quantity,
        'price' => 100,
        'total' => $total,
    ]);

    return $order->fresh(['items']);
}

/**
 * Stands in for the payment providers, so no test ever reaches the network.
 */
function fakeGateway(bool $succeeds, ?string $error = null, ?array &$seen = null): void
{
    $capture = function (Order $order, ?float $amount, ?string $reason) use ($succeeds, $error, &$seen) {
        if ($seen !== null) {
            $seen = ['amount' => $amount, 'reason' => $reason, 'order_id' => $order->id];
        }

        return $succeeds
            ? ['success' => true, 'refund_id' => 'rf_test_1']
            : ['success' => false, 'error' => $error ?? 'declined'];
    };

    $fake = new class($capture) extends PaymentGatewayManager
    {
        public function __construct(private $capture) {}

        public function refund(Order $order, ?float $amount = null, ?string $reason = null): array
        {
            return ($this->capture)($order, $amount, $reason);
        }
    };

    app()->instance(PaymentGatewayManager::class, $fake);
    app()->forgetInstance(OrderService::class);
}

it('puts the stock back when a processing order is cancelled', function () {
    $user = cancelTestUser();
    $product = cancelTestProduct(10);
    $order = cancelTestOrder($user, $product, status: 'processing', quantity: 2);

    fakeGateway(true);

    $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    expect($order->fresh()->status)->toBe('cancelled')
        ->and($product->fresh()->quantity)->toBe(12);
});

it('does not invent stock when a pending order is cancelled', function () {
    // Stock only leaves the shelf when an order reaches processing, so a
    // pending order has nothing to give back. Restoring it anyway would hand
    // the shop units it never had.
    $user = cancelTestUser();
    $product = cancelTestProduct(10);
    $order = cancelTestOrder($user, $product, status: 'pending', quantity: 2);

    fakeGateway(true);

    $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    expect($order->fresh()->status)->toBe('cancelled')
        ->and($product->fresh()->quantity)->toBe(10);
});

it('sends the money back when the order was paid', function () {
    $user = cancelTestUser();
    $product = cancelTestProduct();
    $order = cancelTestOrder(
        $user,
        $product,
        paymentStatus: 'paid',
        paymentMethod: 'stripe',
        total: 200,
    );

    $seen = [];
    fakeGateway(true, seen: $seen);

    $response = $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    expect($seen['amount'])->toBe(200.0)
        ->and($response->json('message'))->toContain('refund');

    $order->refresh();
    expect((float) $order->total_refunded)->toBe(200.0)
        ->and($order->payment_status)->toBe('refunded');

    $refund = Transaction::where('order_id', $order->id)->where('type', 'refund')->first();
    expect($refund)->not->toBeNull()
        ->and($refund->status)->toBe('completed')
        ->and((float) $refund->amount)->toBe(200.0);
});

it('never asks a provider for money that was never taken', function () {
    $user = cancelTestUser();
    $product = cancelTestProduct();
    $order = cancelTestOrder($user, $product, paymentStatus: 'pending');

    $seen = [];
    fakeGateway(true, seen: $seen);

    $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    expect($seen)->toBe([])
        ->and(Transaction::where('order_id', $order->id)->count())->toBe(0)
        ->and($order->fresh()->payment_status)->toBe('pending');
});

it('still cancels, and records the debt, when the refund cannot be sent', function () {
    // Cash on delivery has no provider to call, and a card provider can refuse
    // or be unreachable. The order is still cancelled either way, and what the
    // shop owes is written down instead of being quietly dropped.
    $user = cancelTestUser();
    $product = cancelTestProduct();
    $order = cancelTestOrder(
        $user,
        $product,
        paymentStatus: 'paid',
        paymentMethod: 'cod',
        total: 200,
    );

    fakeGateway(false, 'No payment gateway found for order payment method: cod');

    $response = $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    expect($order->fresh()->status)->toBe('cancelled')
        ->and($response->json('message'))->toContain('refund');

    $order->refresh();
    // The money has not moved, so the order must not claim it has.
    expect($order->payment_status)->toBe('paid')
        ->and((float) $order->total_refunded)->toBe(0.0);

    $refund = Transaction::where('order_id', $order->id)->where('type', 'refund')->first();
    expect($refund)->not->toBeNull()
        ->and($refund->status)->toBe('pending')
        ->and((float) $refund->amount)->toBe(200.0);
});

it('refunds only what is left when part was already returned', function () {
    $user = cancelTestUser();
    $product = cancelTestProduct();
    $order = cancelTestOrder(
        $user,
        $product,
        paymentStatus: 'paid',
        paymentMethod: 'stripe',
        total: 200,
    );
    $order->total_refunded = 50;
    $order->save();

    $seen = [];
    fakeGateway(true, seen: $seen);

    $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    expect($seen['amount'])->toBe(150.0)
        ->and((float) $order->fresh()->total_refunded)->toBe(200.0);
});

it('refuses to cancel an order that has already shipped', function () {
    $user = cancelTestUser();
    $product = cancelTestProduct(10);
    $order = cancelTestOrder($user, $product, status: 'shipped', quantity: 2);

    fakeGateway(true);

    $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertStatus(400)
        ->assertJsonPath('error_code', 'ORDER_CANNOT_BE_CANCELLED');

    expect($order->fresh()->status)->toBe('shipped')
        ->and($product->fresh()->quantity)->toBe(10);
});

it('will not let anyone cancel somebody else\'s order', function () {
    $mine = cancelTestUser();
    $theirs = cancelTestUser();
    $product = cancelTestProduct(10);
    $order = cancelTestOrder($theirs, $product, quantity: 2);

    fakeGateway(true);

    $this->actingAs($mine)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertStatus(404);

    expect($order->fresh()->status)->toBe('processing')
        ->and($product->fresh()->quantity)->toBe(10);
});

it('tells the customer in the order history why it was cancelled', function () {
    $user = cancelTestUser();
    $product = cancelTestProduct();
    $order = cancelTestOrder($user, $product);

    fakeGateway(true);

    $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    $history = OrderHistory::where('order_id', $order->id)->latest()->first();

    expect($history)->not->toBeNull()
        ->and($history->status_to)->toBe('cancelled')
        ->and($history->visible_to_customer)->toBeTrue()
        ->and($history->comment)->toContain('customer');
});

it('returns the cancelled order with its items still on it', function () {
    // The cancel reply is what the app draws straight after the button is
    // pressed. Without the items loaded it would blank the order on screen.
    $user = cancelTestUser();
    $product = cancelTestProduct();
    $order = cancelTestOrder($user, $product, quantity: 2);

    fakeGateway(true);

    $response = $this->actingAs($user)
        ->postJson("/api/v1/customer/orders/{$order->id}/cancel")
        ->assertOk();

    expect($response->json('data.status'))->toBe('cancelled')
        ->and($response->json('data.items'))->toHaveCount(1)
        ->and($response->json('data.items.0.name'))->toBe('Green tea');
});
