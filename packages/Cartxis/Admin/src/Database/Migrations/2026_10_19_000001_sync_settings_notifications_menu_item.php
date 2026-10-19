<?php

declare(strict_types=1);

use Cartxis\Admin\Services\AdminMenuSyncService;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        // Existing stores were seeded before the Notifications settings page
        // existed, and the entrypoint only seeds an empty database. This adds
        // the menu link to stores that are already running.
        app(AdminMenuSyncService::class)->sync();
    }

    public function down(): void
    {
        // Menu sync is additive/corrective; no safe automatic rollback.
    }
};
