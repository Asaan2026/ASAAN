<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * One row per phone the customer has signed in on, so the server knows where
     * to send a push notification. The token comes from Firebase Cloud Messaging
     * and is registered by the app after login.
     *
     * A token is unique across the whole table: when the same phone signs in as a
     * different account, the row is re-pointed rather than duplicated, so a push
     * is never sent to the wrong person on a shared phone.
     */
    public function up(): void
    {
        Schema::create('device_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('token', 512)->unique();
            $table->string('platform', 20)->default('android');
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('device_tokens');
    }
};
