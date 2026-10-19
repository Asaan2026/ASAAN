<?php

namespace Cartxis\Admin\Services;

use App\Models\User;
use Cartxis\Admin\Models\AdminActivityLog;
use Cartxis\Admin\Models\AdminNotification;
use Cartxis\Core\Services\SettingService;
use Illuminate\Support\Facades\DB;

class AdminNotificationService
{
    /**
     * Which dashboard switch controls each kind of notification, by type
     * prefix. Types with no entry here are always allowed, so a new type can
     * never be silenced by a switch the owner has never seen.
     */
    protected const TYPE_SWITCHES = [
        'order' => 'notifications_admin_new_orders',
        'review' => 'notifications_admin_new_reviews',
        'contact' => 'notifications_admin_new_messages',
    ];

    public function __construct(protected SettingService $settings) {}

    /**
     * Create notifications for all active admins.
     */
    public function notifyAllAdmins(
        string $type,
        string $title,
        ?string $message = null,
        ?string $actionUrl = null,
        ?int $actorUserId = null,
        ?string $entityType = null,
        ?int $entityId = null,
        array $meta = [],
        string $severity = 'info'
    ): void {
        if (! $this->allowed($type)) {
            return;
        }

        $adminIds = User::query()
            ->where('role', 'admin')
            ->where('is_active', true)
            ->pluck('id');

        if ($adminIds->isEmpty()) {
            return;
        }

        $now = now();
        $rows = [];

        foreach ($adminIds as $adminId) {
            $rows[] = [
                'recipient_user_id' => $adminId,
                'actor_user_id' => $actorUserId,
                'type' => $type,
                'severity' => $severity,
                'title' => $title,
                'message' => $message,
                'action_url' => $actionUrl,
                'entity_type' => $entityType,
                'entity_id' => $entityId,
                'meta' => empty($meta) ? null : json_encode($meta),
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        DB::table('admin_notifications')->insert($rows);
    }

    /**
     * Does the owner have this kind of notification switched on?
     */
    protected function allowed(string $type): bool
    {
        foreach (self::TYPE_SWITCHES as $prefix => $settingKey) {
            if (str_starts_with($type, $prefix)) {
                return (bool) $this->settings->get($settingKey, true);
            }
        }

        return true;
    }

    /**
     * Write activity log entry.
     */
    public function log(
        string $action,
        ?string $description = null,
        ?int $actorUserId = null,
        ?string $entityType = null,
        ?int $entityId = null,
        array $context = [],
        string $level = 'info'
    ): AdminActivityLog {
        return AdminActivityLog::create([
            'actor_user_id' => $actorUserId,
            'action' => $action,
            'description' => $description,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'context' => empty($context) ? null : $context,
            'level' => $level,
        ]);
    }

    public function unreadCountForAdmin(int $adminUserId): int
    {
        return AdminNotification::query()
            ->where('recipient_user_id', $adminUserId)
            ->whereNull('read_at')
            ->count();
    }
}
