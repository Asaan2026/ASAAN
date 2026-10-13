<?php

use App\Models\User;
use Cartxis\Referral\Models\Referral;

/*
|--------------------------------------------------------------------------
| The referral programme through the app
|--------------------------------------------------------------------------
|
| The website already runs this programme. These tests hold the app to the
| same rules: the same guards on who may be linked, the same refusal when the
| programme is switched off, and the same promise that a wrong code never
| costs somebody the account they were creating.
|
*/

it('will not show anybody their referral page without signing in', function () {
    $this->getJson('/api/v1/referrals')->assertStatus(401);
});

it('gives a customer their code, their share link and their balance', function () {
    configureReferral();

    $admin = referralUser('Store Admin', ['role' => 'admin']);
    $user = referralUser('Ahmad Rahimi');
    credit()->adminCredit($user->id, 50.0, $admin->id, 'Welcome credit');

    $response = $this->actingAs($user)->getJson('/api/v1/referrals')->assertOk();

    expect($response->json('data.referral.code'))->toBe($user->referralCode->code)
        ->and($response->json('data.referral.share_link'))->toContain('?ref='.$user->referralCode->code)
        ->and((float) $response->json('data.balances.available'))->toBe(50.0)
        ->and((float) $response->json('data.programme.reward_amount'))->toBe(10.0)
        ->and((float) $response->json('data.programme.threshold_amount'))->toBe(500.0);
});

it('applies a code to an account that does not have one', function () {
    configureReferral();

    $referrer = referralUser('Ahmad Rahimi');
    $newcomer = referralUser('Sharif Ahmadi');

    $response = $this->actingAs($newcomer)
        ->postJson('/api/v1/referrals/apply', ['code' => $referrer->referralCode->code])
        ->assertOk();

    expect($response->json('data.linked'))->toBeTrue();

    $referral = Referral::where('referred_user_id', $newcomer->id)->first();

    expect($referral)->not->toBeNull()
        ->and($referral->referrer_user_id)->toBe($referrer->id);
});

it('shows who invited the customer once a code has been applied', function () {
    configureReferral();

    $referrer = referralUser('Ahmad Rahimi');
    $newcomer = referralUser('Sharif Ahmadi');

    $this->actingAs($newcomer)
        ->postJson('/api/v1/referrals/apply', ['code' => $referrer->referralCode->code])
        ->assertOk();

    $response = $this->actingAs($newcomer)->getJson('/api/v1/referrals')->assertOk();

    expect($response->json('data.referred_by.name'))->toBe('Ahmad Rahimi');
});

it('refuses to let a customer use their own code', function () {
    configureReferral();

    $user = referralUser('Ahmad Rahimi');

    $response = $this->actingAs($user)
        ->postJson('/api/v1/referrals/apply', ['code' => $user->referralCode->code])
        ->assertStatus(422);

    expect($response->json('error_code'))->toBe('REFERRAL_REFUSED')
        ->and(Referral::where('referred_user_id', $user->id)->count())->toBe(0);
});

it('rejects a code that does not exist', function () {
    configureReferral();

    $user = referralUser('Sharif Ahmadi');

    $response = $this->actingAs($user)
        ->postJson('/api/v1/referrals/apply', ['code' => 'NOT-A-REAL-CODE'])
        ->assertStatus(422);

    expect($response->json('error_code'))->toBe('INVALID_REFERRAL_CODE')
        ->and(array_keys($response->json('errors')))->toContain('code');
});

it('refuses to apply a code while the programme is switched off', function () {
    configureReferral(['enabled' => false]);

    $referrer = referralUser('Ahmad Rahimi');
    $newcomer = referralUser('Sharif Ahmadi');

    $response = $this->actingAs($newcomer)
        ->postJson('/api/v1/referrals/apply', ['code' => $referrer->referralCode->code])
        ->assertStatus(422);

    expect($response->json('error_code'))->toBe('REFERRAL_DISABLED')
        ->and(Referral::count())->toBe(0);
});

it('links a new account created from the app when it carries a code', function () {
    configureReferral();

    $referrer = referralUser('Ahmad Rahimi');

    $this->postJson('/api/v1/auth/register', [
        'name' => 'Sharif Ahmadi',
        'email' => 'sharif@example.test',
        'password' => 'password',
        'password_confirmation' => 'password',
        'terms_accepted' => true,
        'referral_code' => $referrer->referralCode->code,
    ])->assertCreated();

    $newcomer = User::where('email', 'sharif@example.test')->firstOrFail();

    expect(Referral::where('referred_user_id', $newcomer->id)->first()?->referrer_user_id)
        ->toBe($referrer->id);
});

it('still creates the account when the code is wrong', function () {
    configureReferral();

    $referrer = referralUser('Ahmad Rahimi');

    $this->postJson('/api/v1/auth/register', [
        'name' => 'Sharif Ahmadi',
        'email' => 'sharif@example.test',
        'password' => 'password',
        'password_confirmation' => 'password',
        'terms_accepted' => true,
        'referral_code' => 'DEFINITELY-NOT-A-CODE',
    ])->assertCreated();

    expect(User::where('email', 'sharif@example.test')->exists())->toBeTrue()
        ->and(Referral::where('referrer_user_id', $referrer->id)->count())->toBe(0);
});

it('returns the credit history newest first', function () {
    configureReferral();

    $admin = referralUser('Store Admin', ['role' => 'admin']);
    $user = referralUser('Ahmad Rahimi');

    credit()->adminCredit($user->id, 25.0, $admin->id, 'First');
    credit()->adminCredit($user->id, 10.0, $admin->id, 'Second');

    $response = $this->actingAs($user)->getJson('/api/v1/referrals/ledger')->assertOk();

    expect($response->json('meta.total'))->toBe(2)
        ->and((float) $response->json('data.0.amount'))->toBe(10.0)
        ->and((float) $response->json('data.1.amount'))->toBe(25.0);
});
