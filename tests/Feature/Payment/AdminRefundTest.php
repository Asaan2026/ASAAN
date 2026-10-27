<?php

use App\Models\User;
use Cartxis\Core\Services\PaymentGatewayManager;
use Cartxis\Sales\Models\Transaction;
use Cartxis\Sales\Services\TransactionService;
use Cartxis\Shop\Models\Order;
use Illuminate\Support\Str;

/*
|--------------------------------------------------------------------------
| Refunding a payment from the dashboard
|--------------------------------------------------------------------------
|
| The Refund button on a transaction wrote a "pending" refund row, told the
| shop owner it had been created successfully, and never asked the payment
| provider for anything. The money stayed where it was while both sides
| believed a refund was on its way.
|
| These tests hold that path to the only thing that matters: either the
| provider accepted the refund and the order says so, or nothing is claimed.
|
*/

function refundTestOrder(float $total = 200, string $method = 'stripe'): Order
{
    $user = User::create([
        'name' => 'Refund Customer',
        'email' => 'refund-'.Str::random(6).'@example.test',
        'password' => bcrypt('password'),
    ]);

    return Order::create([
        'user_id' => $user->id,
        'order_number' => 'ORD-'.strtoupper(Str::random(8)),
        'status' => 'completed',
        'payment_method' => $method,
        'payment_status' => 'paid',
        'subtotal' => $total,
        'total' => $total,
    ]);
}

function refundTestPayment(Order $order, ?float $amount = null): Transaction
{
    return Transaction::create([
        'order_id' => $order->id,
        'transaction_number' => 'TXN-'.strtoupper(Str::random(8)),
        'type' => 'payment',
        'payment_method' => $order->payment_method,
        'gateway' => $order->payment_method,
        'amount' => $amount ?? $order->total,
        'status' => 'completed',
        'processed_at' => now(),
    ]);
}

/**
 * Stands in for the payment providers so no test reaches the network.
 */
function refundTestGateway(array $reply, ?Throwable $throws = null, ?array &$seen = null): void
{
    $capture = function (Order $order, ?float $amount, ?string $reason) use ($reply, $throws, &$seen) {
        if ($seen !== null) {
            $seen = ['amount' => $amount, 'reason' => $reason];
        }

        if ($throws !== null) {
            throw $throws;
        }

        return $reply;
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
    app()->forgetInstance(TransactionService::class);
}

it('asks the provider for the money and records what came back', function () {
    $order = refundTestOrder(200);
    $payment = refundTestPayment($order);

    $seen = [];
    refundTestGateway(['success' => true, 'refund_id' => 'rf_1'], seen: $seen);

    $refund = app(TransactionService::class)->processRefund($payment, 200.0);

    expect($seen['amount'])->toBe(200.0)
        ->and($refund->type)->toBe('refund')
        ->and($refund->status)->toBe('completed')
        ->and($refund->processed_at)->not->toBeNull();

    $order->refresh();
    expect((float) $order->total_refunded)->toBe(200.0)
        ->and($order->payment_status)->toBe('refunded');
});

it('claims nothing when the provider declines', function () {
    $order = refundTestOrder(200);
    $payment = refundTestPayment($order);

    refundTestGateway(['success' => false, 'error' => 'card no longer valid']);

    expect(fn () => app(TransactionService::class)->processRefund($payment, 200.0))
        ->toThrow(Exception::class, 'card no longer valid');

    $order->refresh();
    expect((float) $order->total_refunded)->toBe(0.0)
        ->and($order->payment_status)->toBe('paid');

    $refund = Transaction::where('order_id', $order->id)->where('type', 'refund')->first();
    expect($refund)->not->toBeNull()
        ->and($refund->status)->toBe('failed')
        ->and($refund->notes)->toContain('card no longer valid');
});

it('records the attempt when there is no provider to call', function () {
    // Cash on delivery has no provider, which arrives as an exception rather
    // than a declined refund.
    $order = refundTestOrder(200, 'cod');
    $payment = refundTestPayment($order);

    refundTestGateway([], new Exception('No payment gateway found for order payment method: cod'));

    expect(fn () => app(TransactionService::class)->processRefund($payment, 200.0))
        ->toThrow(Exception::class, 'No payment gateway found');

    $refund = Transaction::where('order_id', $order->id)->where('type', 'refund')->first();
    expect($refund->status)->toBe('failed')
        ->and((float) $order->fresh()->total_refunded)->toBe(0.0);
});

it('leaves the payment status alone when only part is given back', function () {
    // 'partially_refunded' is not a status the rest of the dashboard reads, so
    // the part refund lives in the figure instead.
    $order = refundTestOrder(200);
    $payment = refundTestPayment($order);

    refundTestGateway(['success' => true]);

    app(TransactionService::class)->processRefund($payment, 50.0);

    $order->refresh();
    expect((float) $order->total_refunded)->toBe(50.0)
        ->and($order->payment_status)->toBe('paid');
});

it('refuses to refund a payment that was never completed', function () {
    $order = refundTestOrder(200);
    $payment = refundTestPayment($order);
    $payment->update(['status' => 'pending']);

    $seen = [];
    refundTestGateway(['success' => true], seen: $seen);

    expect(fn () => app(TransactionService::class)->processRefund($payment, 200.0))
        ->toThrow(Exception::class, 'cannot be refunded');

    expect($seen)->toBe([])
        ->and(Transaction::where('type', 'refund')->count())->toBe(0);
});
