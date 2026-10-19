<?php

namespace Cartxis\Settings\Http\Controllers\Admin;

use Cartxis\API\Services\Push\PushSender;
use Cartxis\Core\Services\SettingService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Dashboard > Settings > Notifications.
 *
 * One page for the push switches the owner actually uses: turn phone push on
 * or off, choose which events reach the customer and which reach the admin
 * team, and fire a test push at the signed-in admin's own phone.
 *
 * The Firebase service-account key stays in the environment (.env), never in
 * the database - this page only displays whether it is configured.
 */
class NotificationSettingsController
{
    protected const SWITCHES = [
        'notifications_push_enabled',
        'notifications_customer_order_updates',
        'notifications_admin_new_orders',
        'notifications_admin_new_reviews',
        'notifications_admin_new_messages',
    ];

    public function __construct(protected SettingService $settings) {}

    public function index(): Response
    {
        return Inertia::render('Admin/Settings/Notifications/Index', [
            'settings' => [
                'notifications_push_enabled' => (bool) $this->settings->get('notifications_push_enabled', true),
                'notifications_customer_order_updates' => (bool) $this->settings->get('notifications_customer_order_updates', true),
                'notifications_admin_new_orders' => (bool) $this->settings->get('notifications_admin_new_orders', true),
                'notifications_admin_new_reviews' => (bool) $this->settings->get('notifications_admin_new_reviews', true),
                'notifications_admin_new_messages' => (bool) $this->settings->get('notifications_admin_new_messages', true),
            ],
            'fcm' => [
                'project_id' => (string) config('services.fcm.project_id', ''),
                'credentials_path' => (string) config('services.fcm.credentials', ''),
                'credentials_present' => filled(config('services.fcm.credentials'))
                    && is_file((string) config('services.fcm.credentials')),
                'notification_channel' => (string) config('services.fcm.notification_channel', ''),
            ],
        ]);
    }

    public function save(Request $request): RedirectResponse
    {
        $validated = $request->validate(
            collect(self::SWITCHES)->mapWithKeys(fn ($key) => [$key => 'nullable|boolean'])->all(),
        );

        foreach (self::SWITCHES as $key) {
            $this->settings->set($key, (bool) ($validated[$key] ?? false), 'boolean', 'notifications');
        }

        return redirect()
            ->route('admin.settings.notifications.index')
            ->with('success', 'Notification settings saved successfully.');
    }

    /**
     * Send a push to the calling admin's own registered phones only, so the
     * owner can prove push works without placing an order or telling every
     * customer the store is testing.
     */
    public function sendTestPush(Request $request): RedirectResponse
    {
        $user = $request->user();

        $tokens = $user ? $user->deviceTokens()->get() : collect();

        if ($tokens->isEmpty()) {
            return redirect()
                ->route('admin.settings.notifications.index')
                ->with('error', 'No phone is signed in with this admin account. Open the phone app, sign in, then try again.');
        }

        $push = app(PushSender::class);

        if (! $push->isConfigured()) {
            return redirect()
                ->route('admin.settings.notifications.index')
                ->with('error', 'Push is not configured yet. Add the Firebase credentials file and set the project id in .env.');
        }

        if (! (bool) $this->settings->get('notifications_push_enabled', true)) {
            return redirect()
                ->route('admin.settings.notifications.index')
                ->with('error', 'Push is switched off. Turn on "Send push notifications to phones" and save first.');
        }

        foreach ($tokens as $device) {
            $push->send(
                $device->token,
                'Test notification',
                'Push is working. This test was sent from the dashboard.',
                ['screen' => 'notifications'],
                'test',
            );
        }

        return redirect()
            ->route('admin.settings.notifications.index')
            ->with('success', 'Test push sent to '.($tokens->count() === 1 ? '1 phone' : $tokens->count().' phones').'.');
    }
}
