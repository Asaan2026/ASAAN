<?php

namespace Cartxis\API\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * A notification shown to a customer in the app.
 *
 * @property int $id
 * @property int $user_id
 * @property string $type
 * @property string $title
 * @property string $body
 * @property array|null $data
 * @property Carbon|null $read_at
 * @property Carbon $created_at
 */
class CustomerNotification extends Model
{
    protected $table = 'customer_notifications';

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'body',
        'data',
        'read_at',
    ];

    protected $casts = [
        'data' => 'array',
        'read_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeUnread(Builder $query): Builder
    {
        return $query->whereNull('read_at');
    }

    public function isRead(): bool
    {
        return $this->read_at !== null;
    }

    /**
     * Mark this notification as read. Answers whether anything changed, so the
     * caller can tell a first tap from a second one.
     */
    public function markAsRead(): bool
    {
        if ($this->read_at !== null) {
            return false;
        }

        $this->forceFill(['read_at' => now()])->save();

        return true;
    }
}
