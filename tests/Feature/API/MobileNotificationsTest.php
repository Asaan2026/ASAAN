<?php

use App\Models\User;
use Cartxis\API\Models\CustomerNotification;
use Cartxis\API\Models\DeviceToken;
use Cartxis\API\Services\CustomerNotificationService;
use Cartxis\API\Services\Push\PushSender;
use Cartxis\Shop\Models\Order;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

/**
 * A push sender that records what it was asked to send and always accepts, so a
 * test can prove a push was attempted without a real Firebase project.
 */
class RecordingPushSender implements PushSender
{
    /** @var list<array{token: string, title: string, type: string}> */
    public array $sent = [];

    public function send(string $token, string $title, string $body, array $data = [], string $type = 'general'): bool
    {
        $this->sent[] = ['token' => $token, 'title' => $title, 'type' => $type];

        return true;
    }

    public function isConfigured(): bool
    {
        return true;
    }
}

/*
|--------------------------------------------------------------------------
| The customer's notifications in the app
|--------------------------------------------------------------------------
|
| The bell on the home screen and its Notifications screen read from these
| endpoints. These tests hold three promises: a customer only ever sees their
| own notifications, the unread count matches what is unread, and a change to an
| order reaches the person who placed it.
|
*/

beforeEach(function () {
    // A test must never reach Google or Firebase for real. Registering a device
    // can trigger a push, and a live OAuth call needs a CA bundle (absent on
    // some machines), so the suite would fail for a reason that has nothing to
    // do with the code under test.
    Http::fake();
});

function notificationUser(string $name = 'Test Customer'): User
{
    return User::create([
        'name' => $name,
        'email' => Str::lower(Str::random(8)).'@example.test',
        'password' => 'password',
        'role' => 'customer',
        'is_active' => true,
    ]);
}

function aNotification(User $user, array $overrides = []): CustomerNotification
{
    return CustomerNotification::create(array_merge([
        'user_id' => $user->id,
        'type' => 'general',
        'title' => 'Hello',
        'body' => 'Something happened.',
        'read_at' => null,
    ], $overrides));
}

it('will not show notifications to anyone who is not signed in', function () {
    $this->getJson('/api/v1/notifications')->assertStatus(401);
    $this->getJson('/api/v1/notifications/unread-count')->assertStatus(401);
});

it('lists only the signed-in customer’s own notifications', function () {
    $mine = notificationUser('Ahmad Rahimi');
    $theirs = notificationUser('Sharif Ahmadi');

    aNotification($mine, ['title' => 'Mine 1']);
    aNotification($mine, ['title' => 'Mine 2']);
    aNotification($theirs, ['title' => 'Not mine']);

    $response = $this->actingAs($mine)->getJson('/api/v1/notifications')->assertOk();

    $titles = array_column($response->json('data'), 'title');

    expect($titles)->toContain('Mine 1')
        ->and($titles)->toContain('Mine 2')
        ->and($titles)->not->toContain('Not mine')
        ->and($response->json('meta.total'))->toBe(3);
});

it('counts only the unread notifications for the signed-in customer', function () {
    $user = notificationUser();

    aNotification($user);
    aNotification($user);
    aNotification($user, ['read_at' => now()]);
    aNotification(notificationUser());

    $response = $this->actingAs($user)->getJson('/api/v1/notifications/unread-count')->assertOk();

    // Two manual notifications plus the welcome every new account receives.
    expect($response->json('data.unread_count'))->toBe(3);
});

it('marks one notification as read', function () {
    $user = notificationUser();
    $notification = aNotification($user);

    $response = $this->actingAs($user)
        ->postJson("/api/v1/notifications/{$notification->id}/read")
        ->assertOk();

    expect($response->json('data.read'))->toBeTrue()
        ->and($notification->fresh()->read_at)->not->toBeNull();
});

it('refuses to mark a notification that belongs to someone else', function () {
    $mine = notificationUser('Ahmad Rahimi');
    $theirs = notificationUser('Sharif Ahmadi');
    $notification = aNotification($theirs);

    $this->actingAs($mine)
        ->postJson("/api/v1/notifications/{$notification->id}/read")
        ->assertStatus(404);

    expect($notification->fresh()->read_at)->toBeNull();
});

it('marks all of the customer’s notifications as read', function () {
    $user = notificationUser();
    aNotification($user);
    aNotification($user);
    $otherUser = notificationUser();
    $other = aNotification($otherUser);

    $response = $this->actingAs($user)->postJson('/api/v1/notifications/read-all')->assertOk();

    // Two manual notifications plus the welcome every new account receives.
    expect($response->json('data.marked_read'))->toBe(3)
        ->and($other->fresh()->read_at)->toBeNull();
});

it('registers a device token and moves it to the newest account', function () {
    $first = notificationUser('Ahmad Rahimi');
    $second = notificationUser('Sharif Ahmadi');

    $this->actingAs($first)
        ->postJson('/api/v1/devices', ['token' => 'device-abc', 'platform' => 'android'])
        ->assertOk();

    $this->actingAs($second)
        ->postJson('/api/v1/devices', ['token' => 'device-abc', 'platform' => 'android'])
        ->assertOk();

    expect(DeviceToken::where('token', 'device-abc')->count())->toBe(1)
        ->and(DeviceToken::where('token', 'device-abc')->first()->user_id)->toBe($second->id);
});

it('tells the customer when their order status changes', function () {
    $user = notificationUser();

    $order = Order::create([
        'user_id' => $user->id,
        'customer_email' => $user->email,
        'order_number' => 'ORD-TEST-0001',
        'status' => Order::STATUS_PENDING,
        'subtotal' => 100,
        'tax' => 0,
        'shipping_cost' => 0,
        'discount' => 0,
        'credit_applied' => 0,
        'total' => 100,
        'payment_method' => 'cod',
        'payment_status' => 'pending',
    ]);

    // Placing the order already told them it was received, on top of the
    // welcome every new account gets.
    expect(CustomerNotification::where('user_id', $user->id)->count())->toBe(2);

    $order->update(['status' => Order::STATUS_PROCESSING]);

    $latest = CustomerNotification::where('user_id', $user->id)->latest('id')->first();

    expect($latest->title)->toContain('prepared')
        ->and($latest->data['order_number'])->toBe('ORD-TEST-0001');

    // An unrelated change must not fire another notification.
    $before = CustomerNotification::where('user_id', $user->id)->count();
    $order->update(['notes' => 'Left at the gate']);

    expect(CustomerNotification::where('user_id', $user->id)->count())->toBe($before);
});

it('does not notify for an order with no account behind it', function () {
    Order::create([
        'user_id' => null,
        'customer_email' => 'guest@example.test',
        'order_number' => 'ORD-GUEST-0001',
        'status' => Order::STATUS_PENDING,
        'subtotal' => 50,
        'total' => 50,
        'payment_method' => 'cod',
        'payment_status' => 'pending',
    ]);

    expect(CustomerNotification::count())->toBe(0);
});

it('creates a notification through the service and reports it unread', function () {
    $user = notificationUser();

    app(CustomerNotificationService::class)->notify(
        $user,
        'promo',
        'Weekend sale',
        'Up to 30% off this weekend.',
        ['link' => '/products'],
    );

    $response = $this->actingAs($user)->getJson('/api/v1/notifications/unread-count')->assertOk();

    // The service's notification plus the welcome every new account receives.
    expect($response->json('data.unread_count'))->toBe(2);
});

it('welcomes a brand-new customer with a notification', function () {
    $user = notificationUser();

    $welcome = CustomerNotification::where('user_id', $user->id)
        ->where('type', 'welcome')
        ->first();

    expect($welcome)->not->toBeNull()
        ->and($welcome->title)->toContain('Welcome')
        ->and($welcome->read_at)->toBeNull();
});

it('does not welcome a staff account created with another role', function () {
    $admin = User::create([
        'name' => 'Shop Owner',
        'email' => Str::lower(Str::random(8)).'@example.test',
        'password' => 'password',
        'role' => 'admin',
        'is_active' => true,
    ]);

    expect(CustomerNotification::where('user_id', $admin->id)->count())->toBe(0);
});

it('pushes the welcome to the phone the first time it registers a token', function () {
    $pusher = new RecordingPushSender;

    $this->app->instance(PushSender::class, $pusher);
    // Rebuild the service so it uses the recording sender.
    $this->app->forgetInstance(CustomerNotificationService::class);

    $user = notificationUser();

    $this->actingAs($user)
        ->postJson('/api/v1/devices', ['token' => 'device-welcome-1', 'platform' => 'android'])
        ->assertOk();

    $welcomePushes = array_filter($pusher->sent, fn ($push) => $push['type'] === 'welcome');

    expect($welcomePushes)->toHaveCount(1)
        ->and($user->customerNotifications()->where('type', 'welcome')->first()->data['pushed'] ?? false)->toBeTrue();

    // A second registration on the same phone must not push the welcome again.
    $this->actingAs($user)
        ->postJson('/api/v1/devices', ['token' => 'device-welcome-1', 'platform' => 'android'])
        ->assertOk();

    $welcomePushes = array_filter($pusher->sent, fn ($push) => $push['type'] === 'welcome');

    expect($welcomePushes)->toHaveCount(1);
});
