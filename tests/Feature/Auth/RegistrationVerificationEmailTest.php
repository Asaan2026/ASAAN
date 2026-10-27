<?php

use App\Models\User;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Facades\Notification;

/*
|--------------------------------------------------------------------------
| The email a new customer is supposed to receive
|--------------------------------------------------------------------------
|
| Registering on the storefront is meant to send a "confirm your email"
| message. This holds that promise to the wiring rather than to the mail
| server: it checks the notification is actually raised for the new account,
| so a missing email can be told apart from a mail server that is not
| delivering.
|
*/

it('raises a verification email for a newly registered customer', function () {
    Notification::fake();

    $this->post('/register', [
        'name' => 'New Customer',
        'email' => 'new-customer@example.test',
        'password' => 'Password123!',
        'password_confirmation' => 'Password123!',
    ])->assertRedirect();

    $user = User::where('email', 'new-customer@example.test')->firstOrFail();

    expect($user->hasVerifiedEmail())->toBeFalse();

    Notification::assertSentTo($user, VerifyEmail::class);
});

it('can send the verification email again on request', function () {
    Notification::fake();

    $user = User::create([
        'name' => 'Waiting Customer',
        'email' => 'waiting@example.test',
        'password' => bcrypt('Password123!'),
    ]);

    $this->actingAs($user)
        ->post('/email/verification-notification')
        ->assertRedirect();

    Notification::assertSentTo($user, VerifyEmail::class);
});

it('raises it for a customer who signs up in the app too', function () {
    Notification::fake();

    $this->postJson('/api/v1/auth/register', [
        'name' => 'App Customer',
        'email' => 'app-customer@example.test',
        'password' => 'Password123!',
        'password_confirmation' => 'Password123!',
        'terms_accepted' => true,
    ])->assertCreated();

    $user = User::where('email', 'app-customer@example.test')->firstOrFail();

    Notification::assertSentTo($user, VerifyEmail::class);
});
