<?php

use App\Models\User;
use Cartxis\API\Services\Push\FcmCredentials;
use Cartxis\API\Services\Push\NullPushSender;
use Cartxis\API\Services\Push\PushSender;
use Cartxis\Core\Services\SettingService;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

/*
|--------------------------------------------------------------------------
| Switching push notifications on from the dashboard
|--------------------------------------------------------------------------
|
| Push only works once Firebase's service-account key is on the server. That
| used to mean someone editing .env and copying a file in over SSH, which a
| shop owner cannot do — and until it was done, no push of any kind was sent,
| so the app looked as though notifications were broken.
|
| The key can now be uploaded in Settings > Notifications. These tests cover
| the two things that matter: a real key switches push on, and anything else
| is refused with something the owner can act on.
|
*/

function pushAdmin(): User
{
    return User::create([
        'name' => 'Shop Owner',
        'email' => 'owner-'.Str::random(6).'@example.test',
        'password' => bcrypt('password'),
        'role' => 'admin',
        // The admin guard turns away an account that is not active.
        'is_active' => true,
    ]);
}

function serviceAccountJson(string $projectId = 'asaan-test'): string
{
    return json_encode([
        'type' => 'service_account',
        'project_id' => $projectId,
        'private_key_id' => 'abc123',
        'private_key' => "-----BEGIN PRIVATE KEY-----\nnot-a-real-key\n-----END PRIVATE KEY-----\n",
        'client_email' => "firebase-adminsdk@{$projectId}.iam.gserviceaccount.com",
        'client_id' => '1234567890',
        'token_uri' => 'https://oauth2.googleapis.com/token',
    ], JSON_PRETTY_PRINT);
}

function uploadedKey(string $contents, string $name = 'service-account.json'): UploadedFile
{
    $path = tempnam(sys_get_temp_dir(), 'fcm').'.json';
    file_put_contents($path, $contents);

    return new UploadedFile($path, $name, 'application/json', null, true);
}

beforeEach(function () {
    // This machine has a key named in its own .env, which would otherwise be
    // in charge for every test here. Each test states its own world instead.
    config()->set('services.fcm.credentials', null);
    config()->set('services.fcm.project_id', null);
});

afterEach(function () {
    $stored = app(FcmCredentials::class)->storedPath();
    if (is_file($stored)) {
        unlink($stored);
    }
});

it('turns push on when a real key is uploaded', function () {
    // Nothing configured: the app must not pretend it can reach phones.
    expect(app(PushSender::class))->toBeInstanceOf(NullPushSender::class);

    $this->actingAs(pushAdmin(), 'admin')
        ->post('/admin/settings/notifications/firebase-key', [
            'key' => uploadedKey(serviceAccountJson('asaan-live')),
        ])
        ->assertRedirect()
        ->assertSessionHas('success');

    $credentials = app(FcmCredentials::class);

    expect($credentials->hasStoredKey())->toBeTrue()
        ->and($credentials->source())->toBe('dashboard')
        // Read from the key itself, so the owner never types it wrongly.
        ->and($credentials->projectId())->toBe('asaan-live')
        ->and($credentials->storedClientEmail())->toContain('asaan-live');

    expect(app(SettingService::class)->get('notifications_fcm_project_id'))
        ->toBe('asaan-live');

    // The sender is now the real one rather than the do-nothing stand-in.
    expect(app(PushSender::class))->not->toBeInstanceOf(NullPushSender::class);
});

it('keeps the key out of the public web root', function () {
    $this->actingAs(pushAdmin(), 'admin')
        ->post('/admin/settings/notifications/firebase-key', [
            'key' => uploadedKey(serviceAccountJson()),
        ])
        ->assertRedirect();

    $stored = app(FcmCredentials::class)->storedPath();

    // Windows mixes the two separators, so normalise before comparing.
    $normalised = str_replace(DIRECTORY_SEPARATOR, '/', $stored);
    $publicDir = str_replace(DIRECTORY_SEPARATOR, '/', public_path());

    expect($normalised)->toContain('storage/app/private/fcm/')
        ->and($normalised)->not->toContain('app/public')
        ->and(str_contains($normalised, $publicDir))->toBeFalse();
});

it('refuses a file that is not a service-account key', function () {
    $this->actingAs(pushAdmin(), 'admin')
        ->post('/admin/settings/notifications/firebase-key', [
            'key' => uploadedKey('{"apiKey":"AIza...","appId":"1:2:web:3"}'),
        ])
        ->assertRedirect()
        ->assertSessionHas('error');

    expect(app(FcmCredentials::class)->hasStoredKey())->toBeFalse()
        ->and(app(PushSender::class))->toBeInstanceOf(NullPushSender::class);
});

it('refuses something that is not JSON at all', function () {
    $this->actingAs(pushAdmin(), 'admin')
        ->post('/admin/settings/notifications/firebase-key', [
            'key' => uploadedKey('this is not json', 'notes.txt'),
        ])
        ->assertRedirect()
        ->assertSessionHas('error');

    expect(app(FcmCredentials::class)->hasStoredKey())->toBeFalse();
});

it('says which field is missing when the key is incomplete', function () {
    $incomplete = json_encode([
        'type' => 'service_account',
        'project_id' => 'asaan-test',
        'client_email' => 'x@y.iam.gserviceaccount.com',
    ]);

    $response = $this->actingAs(pushAdmin(), 'admin')
        ->post('/admin/settings/notifications/firebase-key', ['key' => uploadedKey($incomplete)]);

    $response->assertRedirect();
    expect(session('error'))->toContain('private_key');
    expect(app(FcmCredentials::class)->hasStoredKey())->toBeFalse();
});

it('lets the owner remove a key that was wrong', function () {
    $admin = pushAdmin();

    $this->actingAs($admin, 'admin')
        ->post('/admin/settings/notifications/firebase-key', [
            'key' => uploadedKey(serviceAccountJson()),
        ])->assertRedirect();

    expect(app(FcmCredentials::class)->hasStoredKey())->toBeTrue();

    $this->actingAs($admin, 'admin')
        ->delete('/admin/settings/notifications/firebase-key')
        ->assertRedirect()
        ->assertSessionHas('success');

    expect(app(FcmCredentials::class)->hasStoredKey())->toBeFalse()
        ->and(app(SettingService::class)->get('notifications_fcm_project_id'))->toBeNull();
});

it('leaves a server-configured key in charge', function () {
    // A shop set up the old way must keep working exactly as it did.
    $serverKey = tempnam(sys_get_temp_dir(), 'server-fcm').'.json';
    file_put_contents($serverKey, serviceAccountJson('from-the-server'));

    config()->set('services.fcm.credentials', $serverKey);
    config()->set('services.fcm.project_id', 'from-the-server');

    $this->actingAs(pushAdmin(), 'admin')
        ->post('/admin/settings/notifications/firebase-key', [
            'key' => uploadedKey(serviceAccountJson('uploaded-here')),
        ])->assertRedirect();

    $credentials = app(FcmCredentials::class);

    expect($credentials->source())->toBe('server')
        ->and($credentials->credentialsPath())->toBe($serverKey)
        ->and($credentials->projectId())->toBe('from-the-server');

    unlink($serverKey);
});

it('needs an admin to be signed in', function () {
    $this->post('/admin/settings/notifications/firebase-key', [
        'key' => uploadedKey(serviceAccountJson()),
    ])->assertRedirect();

    expect(app(FcmCredentials::class)->hasStoredKey())->toBeFalse();
});
