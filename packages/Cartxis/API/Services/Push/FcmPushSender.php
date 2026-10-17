<?php

namespace Cartxis\API\Services\Push;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Push notifications over Firebase Cloud Messaging (HTTP v1 API).
 *
 * FCM's v1 endpoint is not open: the server has to prove who it is with a short
 * Google OAuth token. That token is built from the service-account JSON the
 * owner downloads once from the Firebase console -- no extra package is needed,
 * only openssl, which PHP already ships with. The token is cached for its hour so
 * one login is not paid for on every push.
 */
class FcmPushSender implements PushSender
{
    public function __construct(
        protected ?string $projectId,
        protected ?string $credentialsPath,
        protected string $channel = 'asaan_default',
    ) {}

    public function isConfigured(): bool
    {
        return ! empty($this->projectId)
            && ! empty($this->credentialsPath)
            && is_file($this->credentialsPath);
    }

    public function send(string $token, string $title, string $body, array $data = [], string $type = 'general'): bool
    {
        if (! $this->isConfigured() || $token === '') {
            return false;
        }

        $accessToken = $this->accessToken();

        if (! $accessToken) {
            return false;
        }

        // FCM only accepts string values in the data block.
        $stringData = ['type' => (string) $type];
        foreach ($data as $key => $value) {
            if (is_scalar($value)) {
                $stringData[(string) $key] = (string) $value;
            }
        }

        // Only name a notification channel when one is configured. An Android
        // channel that does not exist on the phone makes the message vanish on
        // Android 8+, so with no channel set we let Firebase use its own.
        $android = ['priority' => 'high'];
        if ($this->channel !== '') {
            $android['notification'] = ['channel_id' => $this->channel];
        }

        $response = Http::withToken($accessToken)
            ->acceptJson()
            ->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", [
                'message' => [
                    'token' => $token,
                    'notification' => ['title' => $title, 'body' => $body],
                    'data' => $stringData,
                    'android' => $android,
                    'apns' => [
                        'payload' => ['aps' => ['sound' => 'default']],
                    ],
                ],
            ]);

        if (! $response->successful()) {
            // A dead token (app uninstalled, or the phone signed out) answers
            // 404/410. That is expected and must not look like a fault.
            Log::info('FCM push was not accepted', [
                'status' => $response->status(),
                'body' => $response->json(),
            ]);
        }

        return $response->successful();
    }

    /**
     * A Google access token for the messaging scope, cached until just before it
     * expires. Returns null when the credentials cannot be read or signed.
     */
    protected function accessToken(): ?string
    {
        return Cache::remember('fcm.access_token', now()->addMinutes(50), function () {
            $credentials = $this->credentials();

            if (! $credentials || empty($credentials['client_email']) || empty($credentials['private_key'])) {
                Log::warning('FCM credentials are present but incomplete.');

                return null;
            }

            $now = time();
            $header = $this->base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = $this->base64url(json_encode([
                'iss' => $credentials['client_email'],
                'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => $credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token',
                'iat' => $now,
                'exp' => $now + 3600,
            ]));

            $unsigned = $header.'.'.$claims;
            $signature = '';

            if (! openssl_sign($unsigned, $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256)) {
                Log::warning('FCM service-account key could not sign the token.');

                return null;
            }

            $assertion = $unsigned.'.'.$this->base64url($signature);

            $response = Http::asForm()->post(
                $credentials['token_uri'] ?? 'https://oauth2.googleapis.com/token',
                [
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'assertion' => $assertion,
                ]
            );

            if (! $response->successful()) {
                Log::warning('FCM OAuth token request failed', ['status' => $response->status()]);

                return null;
            }

            return $response->json('access_token');
        });
    }

    /**
     * @return array<string, mixed>|null
     */
    protected function credentials(): ?array
    {
        if (! $this->credentialsPath || ! is_file($this->credentialsPath)) {
            return null;
        }

        $decoded = json_decode((string) file_get_contents($this->credentialsPath), true);

        return is_array($decoded) ? $decoded : null;
    }

    protected function base64url(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
