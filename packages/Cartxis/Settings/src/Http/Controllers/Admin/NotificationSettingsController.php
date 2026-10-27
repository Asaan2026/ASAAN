<?php

namespace Cartxis\Settings\Http\Controllers\Admin;

use Cartxis\API\Services\Push\FcmCredentials;
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
 * The Firebase service-account key can be uploaded here. It is written to the
 * private storage directory, never to the database and never anywhere the web
 * server will serve it. A key named in .env still wins, so a server set up that
 * way keeps working.
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

    public function __construct(
        protected SettingService $settings,
        protected FcmCredentials $credentials,
    ) {}

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
                'project_id' => (string) ($this->credentials->projectId() ?? ''),
                'credentials_path' => (string) ($this->credentials->credentialsPath() ?? ''),
                'credentials_present' => $this->credentials->credentialsPath() !== null,
                'notification_channel' => (string) config('services.fcm.notification_channel', ''),
                // Which of the two places the key came from, so the owner can
                // see at a glance whether their upload is the one in use.
                'source' => $this->credentials->source(),
                'client_email' => (string) ($this->credentials->storedClientEmail() ?? ''),
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
                ->with('error', 'Push is not set up yet. Upload your Firebase service-account key below, then try again.');
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

    /**
     * Take the Firebase service-account key the owner downloaded from the
     * Firebase console and keep it where the server can sign with it.
     *
     * The file is checked before it is kept: a wrong file is refused here,
     * while the owner is still looking at the page, rather than quietly
     * failing at the first push weeks later.
     */
    public function uploadFirebaseKey(Request $request): RedirectResponse
    {
        $request->validate([
            // Firebase hands out a .json file; some browsers report it as
            // plain text, so the contents are what is actually trusted.
            'key' => 'required|file|max:64',
        ]);

        $upload = $request->file('key');
        $checked = $this->credentials->inspect($upload->getRealPath());

        if (! $checked['ok']) {
            return redirect()
                ->route('admin.settings.notifications.index')
                ->with('error', $checked['error']);
        }

        $target = $this->credentials->storedPath();

        if (! is_dir(dirname($target))) {
            mkdir(dirname($target), 0775, true);
        }

        $upload->move(dirname($target), basename($target));
        @chmod($target, 0640);

        $this->settings->set(
            'notifications_fcm_project_id',
            $checked['project_id'],
            'string',
            'notifications',
        );

        return redirect()
            ->route('admin.settings.notifications.index')
            ->with('success', 'Firebase key saved for project '.$checked['project_id'].'. Send a test push to confirm it works.');
    }

    /**
     * Forget the uploaded key, for replacing one that was wrong.
     */
    public function removeFirebaseKey(): RedirectResponse
    {
        if ($this->credentials->hasStoredKey()) {
            @unlink($this->credentials->storedPath());
        }

        $this->settings->delete('notifications_fcm_project_id');

        return redirect()
            ->route('admin.settings.notifications.index')
            ->with('success', 'Firebase key removed. Push is off until a new key is uploaded.');
    }
}
