<?php

namespace Cartxis\API\Services\Push;

/**
 * The sender used when push is not set up.
 *
 * It does nothing and reports honestly that it is not configured, which keeps
 * every caller free of "is push switched on?" checks sprinkled through the code.
 */
class NullPushSender implements PushSender
{
    public function send(string $token, string $title, string $body, array $data = [], string $type = 'general'): bool
    {
        return false;
    }

    public function isConfigured(): bool
    {
        return false;
    }
}
