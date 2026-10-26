<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Models\Concerns\ReferralAwareUserBuilder;
use Cartxis\API\Models\CustomerNotification;
use Cartxis\API\Models\DeviceToken;
use Cartxis\Core\Traits\HasPermissions;
use Cartxis\Customer\Models\Customer;
use Cartxis\Customer\Models\CustomerAddress;
use Cartxis\Customer\Models\Wishlist;
use Cartxis\Referral\Exceptions\ReferralBalanceOutstanding;
use Cartxis\Referral\Models\Referral;
use Cartxis\Referral\Models\ReferralCode;
use Cartxis\Referral\Models\ReferralLedgerEntry;
use Cartxis\Referral\Services\ReferralCreditService;
use Cartxis\Referral\Services\ReferralSettings;
use Cartxis\Sales\Models\Delivery;
use Cartxis\Shop\Models\Order;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasPermissions, Notifiable, TwoFactorAuthenticatable;

    /**
     * Escape hatch for a deliberate erasure of an account that still holds
     * referral credit. Off by default, and never set by any customer-facing path.
     *
     * @var bool
     */
    protected static $deletingWithReferralHistory = false;

    /**
     * Route every query for this model through the builder that refuses to delete
     * accounts still holding referral credit, including bulk deletes.
     */
    public function newEloquentBuilder($query)
    {
        return new ReferralAwareUserBuilder($query);
    }

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'is_active',
        'email_verified_at',
        'profile_photo_path',
        'phone',
        'date_of_birth',
        'gender',
        'avatar',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'two_factor_secret',
        'two_factory_recovery_codes',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
            // Set by the identity review flow only. Deliberately left out of
            // $fillable: a customer must not be able to verify themselves by
            // putting the field in a form. IdentityService writes it with
            // forceFill for the same reason.
            'identity_verified_at' => 'datetime',
        ];
    }

    /**
     * Get the orders for the user.
     */
    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    /**
     * Get the phones this user has signed in on for push notifications.
     */
    public function deviceTokens()
    {
        return $this->hasMany(DeviceToken::class, 'user_id');
    }

    /**
     * Get this user's in-app notifications, newest first through the query.
     */
    public function customerNotifications()
    {
        return $this->hasMany(CustomerNotification::class, 'user_id');
    }

    /**
     * Get the delivery runs assigned to this user (as a driver).
     */
    public function assignedDeliveries()
    {
        return $this->hasMany(Delivery::class, 'assigned_to');
    }

    /**
     * Get the customer record for the user.
     */
    public function customer()
    {
        return $this->hasOne(Customer::class);
    }

    /**
     * Get the addresses for the user.
     */
    public function addresses()
    {
        return $this->hasMany(CustomerAddress::class, 'customer_id');
    }

    /**
     * Get the wishlist items for the user (through customer).
     */
    public function wishlist()
    {
        return $this->hasManyThrough(
            Wishlist::class,
            Customer::class,
            'user_id', // Foreign key on customers table
            'customer_id', // Foreign key on wishlists table
            'id', // Local key on users table
            'id' // Local key on customers table
        );
    }

    /**
     * Get the referral code issued to this user.
     */
    public function referralCode()
    {
        return $this->hasOne(ReferralCode::class, 'user_id');
    }

    /**
     * Get the links where this user is the person who referred.
     */
    public function referralsMade()
    {
        return $this->hasMany(Referral::class, 'referrer_user_id');
    }

    /**
     * Get the link that says who referred this user.
     */
    public function referredBy()
    {
        return $this->hasOne(Referral::class, 'referred_user_id');
    }

    /**
     * Get every movement of this user's referral credit balance.
     */
    public function referralLedger()
    {
        return $this->hasMany(ReferralLedgerEntry::class, 'user_id');
    }

    /**
     * Stop an account being deleted while it still holds referral credit.
     *
     * This sits on the model rather than in one controller because accounts are
     * deleted from the storefront, from the API, from the admin and from artisan.
     * A rule that only lives in the storefront controller is a rule the other
     * three paths walk straight past, and the ledger rows would be cascaded away
     * along with the account.
     *
     * Locked credit counts as held. It is not spendable yet, but it is still owed.
     */
    protected static function booted(): void
    {
        static::deleting(function (self $user) {
            if (static::$deletingWithReferralHistory) {
                return;
            }

            $settings = app(ReferralSettings::class);

            if (! $settings->blocksAccountDeletion()) {
                return;
            }

            $credit = app(ReferralCreditService::class);
            $available = $credit->availableBalance($user->id);
            $locked = $credit->lockedBalance($user->id);

            if ($available <= 0 && $locked <= 0) {
                return;
            }

            throw new ReferralBalanceOutstanding(
                $user->id,
                round($available, 2),
                round($locked, 2)
            );
        });
    }

    /**
     * Allow this account to be deleted even though it holds referral credit.
     *
     * For a deliberate, audited erasure only. Setting it true is the only way to
     * delete an account that still holds money owed to it, and the caller is
     * expected to have written down why.
     *
     * @return bool the previous value, so a caller can restore it
     */
    public static function allowDeletingWithReferralHistory(bool $allow = true): bool
    {
        $previous = static::$deletingWithReferralHistory;
        static::$deletingWithReferralHistory = $allow;

        return $previous;
    }

    /**
     * Whether a deliberate erasure is currently permitted.
     */
    public static function isDeletingWithReferralHistory(): bool
    {
        return static::$deletingWithReferralHistory;
    }
}
