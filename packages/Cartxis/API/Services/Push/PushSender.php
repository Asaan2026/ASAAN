<?php

namespace Cartxis\API\Services\Push;

/**
 * Sends a push notification to one device.
 *
 * The app always gets its in-app notification regardless of what this returns;
 * a push is a best-effort extra. Implementations must never throw for a device
 * that has gone away -- an uninstalled app or an expired token is normal, not an
 * error the customer should ever see.
 */
interface PushSender
{
    /**
     * @param  string  $token  The device's FCM registration token.
     * @param  array<string, mixed>  $data  Extra values handed to the app.
     * @return bool True when the push was accepted by the provider.
     */
    public function send(string $token, string $title, string $body, array $data = [], string $type = 'general'): bool;

    /**
     * Whether a real provider is configured. The service uses this to avoid
     * doing pointless work when push is off.
     */
    public function isConfigured(): bool;
}
