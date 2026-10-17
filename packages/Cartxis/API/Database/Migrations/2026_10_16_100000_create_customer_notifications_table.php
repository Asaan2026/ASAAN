<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * In-app notifications for a signed-in customer, shown by the app's bell and
     * its Notifications screen.
     *
     * Kept separate from the admin `admin_notifications` table on purpose: an
     * admin notice is about running the store, a customer notice is about that
     * person's own order or account. Mixing the two would leak admin messages
     * into the app.
     */
    public function up(): void
    {
        Schema::create('customer_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            // "order", "promo", "general" -- lets the app group or icon them.
            $table->string('type')->default('general');
            $table->string('title');
            $table->text('body');
            // Anything the app needs to open the right screen, e.g. order_number.
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            // The two reads the app makes most: "my list" and "my unread count".
            $table->index(['user_id', 'created_at']);
            $table->index(['user_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_notifications');
    }
};
