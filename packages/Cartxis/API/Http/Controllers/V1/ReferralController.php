<?php

namespace Cartxis\API\Http\Controllers\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Cartxis\API\Helpers\ApiResponse;
use Cartxis\Referral\Models\Referral;
use Cartxis\Referral\Models\ReferralLedgerEntry;
use Cartxis\Referral\Services\ReferralCodeService;
use Cartxis\Referral\Services\ReferralCreditService;
use Cartxis\Referral\Services\ReferralEarningService;
use Cartxis\Referral\Services\ReferralLinkService;
use Cartxis\Referral\Services\ReferralSettings;
use Cartxis\Referral\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * The referral programme for the mobile app.
 *
 * This is the same programme the website already runs, spoken to over JSON.
 * Every rule — who may be linked, what the reward is, when it unlocks — lives
 * in the Referral package; this controller only shapes the answers. If a rule
 * is ever changed, it is changed there, once, and both clients follow.
 */
class ReferralController extends Controller
{
    public function __construct(
        protected ReferralSettings $settings,
        protected ReferralCodeService $codes,
        protected ReferralCreditService $credit,
        protected ReferralEarningService $earning,
        protected ReferralLinkService $links,
    ) {}

    /**
     * The customer's own referral code, balance and invited friends.
     */
    public function show(Request $request)
    {
        $user = $request->user();

        $code = $this->codes->forUser($user);
        $link = $this->codes->shareLinkFor($code);

        return ApiResponse::success([
            'referral' => [
                'code' => $code->code,
                'share_link' => $link,
                'share_text' => $this->shareText($code->code, $link),
                'clicks' => (int) $code->clicks,
                'status' => $code->status,
            ],
            'programme' => [
                'enabled' => $this->settings->isEnabled(),
                'reward_amount' => $this->settings->rewardAmount(),
                'threshold_amount' => $this->settings->thresholdAmount(),
                'lock_days' => $this->settings->lockDays(),
                'credit_max_percent_of_order' => $this->settings->creditMaxPercentOfOrder(),
            ],
            'balances' => $this->credit->balancesFor($user),
            'invited' => Referral::where('referrer_user_id', $user->id)
                ->with('referred')
                ->orderByDesc('created_at')
                ->limit(50)
                ->get()
                ->map(fn (Referral $referral) => [
                    'id' => $referral->id,
                    'name' => $this->maskName($referral->referred?->name),
                    'lifetime_spend' => $this->earning->lifetimeQualifyingSpend($referral->referred_user_id),
                    'rewarded' => $referral->hasBeenRewarded(),
                    'status' => $referral->status,
                    'joined_at' => $referral->created_at?->toIso8601String(),
                ])
                ->values(),
            'referred_by' => $this->referredBy($user),
        ]);
    }

    /**
     * The credit history, newest first.
     */
    public function ledger(Request $request)
    {
        $user = $request->user();

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $paginator = ReferralLedgerEntry::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->orderByDesc('id')
            ->paginate($perPage);

        $paginator->getCollection()->transform(fn (ReferralLedgerEntry $entry) => [
            'id' => $entry->id,
            'type' => $entry->type,
            'amount' => (float) $entry->amount,
            'balance_after' => $entry->balance_after !== null ? (float) $entry->balance_after : null,
            'reason' => $entry->reason,
            'available_from' => $entry->available_from?->toIso8601String(),
            'created_at' => $entry->created_at?->toIso8601String(),
        ]);

        return ApiResponse::paginated($paginator);
    }

    /**
     * Apply a referral code to an account that does not have one yet.
     *
     * A customer who signed up without a code (or who was given one later) can
     * type it here. The same guards that protect signup protect this, so a code
     * can never be used by the person who owns it, twice, or on an account that
     * shares the referrer's email or phone.
     */
    public function apply(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => ['required', 'string', 'max:32'],
        ]);

        if ($validator->fails()) {
            return ApiResponse::validationError($validator);
        }

        if (! $this->settings->isEnabled()) {
            return ApiResponse::error(
                'The referral programme is not available right now.',
                ['code' => ['The referral programme is not available right now.']],
                422,
                'REFERRAL_DISABLED'
            );
        }

        $code = $this->codes->findByCode((string) $request->input('code'));

        if (! $code) {
            $message = 'That referral code is not valid.';

            return ApiResponse::error($message, ['code' => [$message]], 422, 'INVALID_REFERRAL_CODE');
        }

        $result = $this->links->linkToCode($request->user(), $code);

        if ($result['referral'] === null) {
            $message = $this->reasonMessage($result['reason']);

            return ApiResponse::error($message, ['code' => [$message]], 422, 'REFERRAL_REFUSED');
        }

        return ApiResponse::success([
            'linked' => true,
            'level' => $result['referral']->level,
        ], 'Referral code applied.');
    }

    /**
     * Who invited this customer, if anyone did.
     */
    protected function referredBy(User $user): ?array
    {
        $referral = Referral::where('referred_user_id', $user->id)
            ->with('referrer')
            ->first();

        if (! $referral || ! $referral->referrer) {
            return null;
        }

        return [
            'name' => $referral->referrer->name,
        ];
    }

    /**
     * Turn a machine reason into something a customer can act on.
     */
    protected function reasonMessage(?string $reason): string
    {
        return match ($reason) {
            ReferralLinkService::REASON_SELF => 'You cannot use your own referral code.',
            ReferralLinkService::REASON_ALREADY_LINKED => 'A referral code has already been used on this account.',
            ReferralLinkService::REASON_SAME_EMAIL => 'This account shares an email address with the person who sent the code.',
            ReferralLinkService::REASON_SAME_PHONE => 'This account shares a phone number with the person who sent the code.',
            ReferralLinkService::REASON_TOO_DEEP => 'This referral cannot be linked right now.',
            default => 'This referral code could not be applied.',
        };
    }

    /**
     * Show only the first letter of a name, so the invited list does not become
     * a list of everybody's full name on a screen other people can see.
     */
    protected function maskName(?string $name): string
    {
        $name = trim((string) $name);

        if ($name === '') {
            return 'A customer';
        }

        $mask = fn (string $part) => mb_substr($part, 0, 1).str_repeat('*', max(2, mb_strlen($part) - 1));

        $parts = array_values(array_filter(preg_split('/\s+/u', $name) ?: []));

        if (count($parts) === 1) {
            return $mask($parts[0]);
        }

        return $mask($parts[0]).' '.$mask($parts[count($parts) - 1]);
    }

    /**
     * The message a customer would send in a message app, so sharing is one tap.
     *
     * Only the person who sends the link earns, so the wording must not promise
     * the friend a reward that was never offered to them.
     */
    protected function shareText(string $code, string $link): string
    {
        return __('Join with my link and I earn :reward of store credit when you have spent :threshold. My code is :code. :link', [
            'link' => $link,
            'code' => $code,
            'threshold' => Money::inSentence($this->settings->thresholdAmount()),
            'reward' => Money::inSentence($this->settings->rewardAmount()),
        ]);
    }
}
