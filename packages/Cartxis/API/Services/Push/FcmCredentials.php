<?php

namespace Cartxis\API\Services\Push;

use Cartxis\Core\Services\SettingService;
use Illuminate\Support\Facades\Log;

/**
 * Where the Firebase service-account key comes from.
 *
 * Push used to work only if somebody put the key file on the server by hand and
 * named it in .env. That is a step a shop owner cannot take from the dashboard,
 * and until it was taken no push of any kind was sent -- the shop looked as
 * though notifications were broken when they had simply never been switched on.
 *
 * So the key can now be uploaded in Settings > Notifications. It is written to
 * the private storage directory, which is kept outside the public web root and
 * mounted from the host, so it survives a redeploy. The file named in .env is
 * still honoured and still wins, so a server that was set up the old way keeps
 * working untouched.
 */
class FcmCredentials
{
    /**
     * Where an uploaded key is kept. Under storage/app/private, which nginx
     * never serves.
     */
    public const STORED_RELATIVE_PATH = 'private/fcm/service-account.json';

    public function __construct(protected SettingService $settings) {}

    public function storedPath(): string
    {
        return storage_path('app/'.self::STORED_RELATIVE_PATH);
    }

    public function hasStoredKey(): bool
    {
        return is_file($this->storedPath());
    }

    /**
     * The key file to sign with: the one named in .env if it is really there,
     * otherwise the uploaded one.
     */
    public function credentialsPath(): ?string
    {
        $fromEnv = (string) config('services.fcm.credentials', '');

        if ($fromEnv !== '' && is_file($fromEnv)) {
            return $fromEnv;
        }

        return $this->hasStoredKey() ? $this->storedPath() : null;
    }

    /**
     * The Firebase project to send to. Taken from whichever source supplied the
     * key, so the two can never be mismatched.
     */
    public function projectId(): ?string
    {
        $fromEnv = (string) config('services.fcm.project_id', '');
        $envFile = (string) config('services.fcm.credentials', '');

        if ($fromEnv !== '' && $envFile !== '' && is_file($envFile)) {
            return $fromEnv;
        }

        $stored = $this->storedProjectId();

        if ($stored !== null) {
            return $stored;
        }

        return $fromEnv !== '' ? $fromEnv : null;
    }

    /**
     * The project id read out of the uploaded key itself, so the owner never
     * has to type it.
     */
    public function storedProjectId(): ?string
    {
        if (! $this->hasStoredKey()) {
            return null;
        }

        $parsed = $this->read($this->storedPath());

        return $parsed['project_id'] ?? null;
    }

    public function storedClientEmail(): ?string
    {
        if (! $this->hasStoredKey()) {
            return null;
        }

        return $this->read($this->storedPath())['client_email'] ?? null;
    }

    /**
     * Which of the two sources is actually in use, for the dashboard to show.
     */
    public function source(): string
    {
        $fromEnv = (string) config('services.fcm.credentials', '');

        if ($fromEnv !== '' && is_file($fromEnv)) {
            return 'server';
        }

        return $this->hasStoredKey() ? 'dashboard' : 'none';
    }

    /**
     * Check that a file really is a Firebase service-account key before it is
     * trusted, so a wrong file is refused while the owner is still looking at
     * the page rather than silently failing at the first push.
     *
     * @return array{ok: bool, error: ?string, project_id: ?string, client_email: ?string}
     */
    public function inspect(string $path): array
    {
        $fail = fn (string $why) => [
            'ok' => false,
            'error' => $why,
            'project_id' => null,
            'client_email' => null,
        ];

        $parsed = $this->read($path);

        if ($parsed === []) {
            return $fail('That file is not readable as JSON. Download the key again from the Firebase console.');
        }

        if (($parsed['type'] ?? null) !== 'service_account') {
            return $fail('That is not a service-account key. In the Firebase console open Project settings > Service accounts and choose "Generate new private key".');
        }

        foreach (['project_id', 'private_key', 'client_email'] as $required) {
            if (empty($parsed[$required])) {
                return $fail("The key is missing its {$required}. Download it again from the Firebase console.");
            }
        }

        return [
            'ok' => true,
            'error' => null,
            'project_id' => (string) $parsed['project_id'],
            'client_email' => (string) $parsed['client_email'],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    protected function read(string $path): array
    {
        try {
            $contents = @file_get_contents($path);

            if ($contents === false) {
                return [];
            }

            $decoded = json_decode($contents, true);

            return is_array($decoded) ? $decoded : [];
        } catch (\Throwable $e) {
            Log::warning('Could not read the Firebase key', [
                'path' => $path,
                'error' => $e->getMessage(),
            ]);

            return [];
        }
    }
}
