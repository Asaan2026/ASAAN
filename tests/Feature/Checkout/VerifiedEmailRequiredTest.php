<?php

use App\Models\User;
use Cartxis\Core\Services\SettingService;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Str;

/*
|--------------------------------------------------------------------------
| Confirming your email before you can buy
|--------------------------------------------------------------------------
|
| Browsing and filling a basket are open to anyone. Placing an order is not:
| the customer must have an account and must have confirmed the address on it.
|
| The rule has to hold on the website and in the app, and it is one middleware
| so the two cannot drift. These tests check both doors, and the switch that
| lets the shop owner turn it off if their customers cannot receive email.
|
*/

function buyer(bool $verified): User
{
    return User::create([
        'name' => 'Buyer',
        'email' => 'buyer-'.Str::random(6).'@example.test',
        'password' => bcrypt('password'),
        'email_verified_at' => $verified ? now() : null,
    ]);
}

it('refuses an order from the app when the email is not confirmed', function () {
    $response = $this->actingAs(buyer(false))
        ->postJson('/api/v1/checkout/place-order', ['payment_method' => 'cod']);

    $response->assertStatus(403)
        ->assertJsonPath('error_code', 'EMAIL_NOT_VERIFIED');

    // The message names the address, so the customer knows where to look.
    expect($response->json('message'))->toContain('confirm your email');
});

it('lets a confirmed customer through to the app checkout', function () {
    // Past the gate: whatever the checkout then says about an empty basket is
    // its own business, but it must not be the verification refusal.
    $response = $this->actingAs(buyer(true))
        ->postJson('/api/v1/checkout/place-order', ['payment_method' => 'cod']);

    expect($response->json('error_code'))->not->toBe('EMAIL_NOT_VERIFIED');
});

it('refuses an order from the website when the email is not confirmed', function () {
    $this->actingAs(buyer(false))
        ->post('/checkout', [
            'email' => 'buyer@example.test',
            'shipping_address' => ['first_name' => 'A'],
        ])
        ->assertSessionHasErrors('email_verification');
});

it('asks a signed-out visitor to sign in rather than taking the order', function () {
    $this->postJson('/api/v1/checkout/place-order', ['payment_method' => 'cod'])
        ->assertStatus(401);
});

it('can be switched off by the shop owner', function () {
    // A shop whose customers cannot receive email must still be able to sell.
    app(SettingService::class)->set('checkout_require_verified_email', false, 'boolean', 'store');

    $response = $this->actingAs(buyer(false))
        ->postJson('/api/v1/checkout/place-order', ['payment_method' => 'cod']);

    expect($response->json('error_code'))->not->toBe('EMAIL_NOT_VERIFIED');
});

it('sends the confirmation link again when the app asks', function () {
    Notification::fake();

    $user = buyer(false);

    $this->actingAs($user)
        ->postJson('/api/v1/auth/email/resend')
        ->assertOk()
        ->assertJsonPath('data.verified', false);

    Notification::assertSentTo($user, VerifyEmail::class);
});

it('says so plainly when the address is already confirmed', function () {
    Notification::fake();

    $this->actingAs(buyer(true))
        ->postJson('/api/v1/auth/email/resend')
        ->assertOk()
        ->assertJsonPath('data.verified', true);

    Notification::assertNothingSent();
});
