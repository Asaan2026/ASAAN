<?php

namespace Cartxis\API\Observers;

use App\Models\User;
use Cartxis\API\Services\CustomerNotificationService;

/**
 * Welcomes a brand-new customer, so an empty bell never looks broken.
 *
 * It hangs off the User model rather than the register screen, so every path
 * that creates an account -- the phone app, the website, an import, artisan --
 * produces the same welcome. A welcome that only lived in one screen would be
 * missing from the others, which is exactly what a customer would notice.
 */
class WelcomeNotificationObserver
{
    public function __construct(protected CustomerNotificationService $notifications) {}

    public function created(User $user): void
    {
        // Only customers get a welcome. A staff or admin account created from
        // the dashboard has no storefront bell to fill.
        if ($user->role !== null && $user->role !== 'customer') {
            return;
        }

        $this->notifications->notify(
            $user,
            'welcome',
            'Welcome to Asaan',
            'Thanks for joining us. Browse the store, and we will keep you posted on your orders and offers.',
        );
    }
}
