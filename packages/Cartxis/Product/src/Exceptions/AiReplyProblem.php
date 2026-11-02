<?php

namespace Cartxis\Product\Exceptions;

use RuntimeException;

/**
 * Thrown when the AI answered but the answer is no use yet.
 *
 * The kind matters because some of these are worth trying again on the spot —
 * a free model that was busy, or one that ran out of room mid-sentence and
 * needs a bigger allowance — and the shopkeeper should never have to know
 * that, let alone go and change a setting themselves.
 */
class AiReplyProblem extends RuntimeException
{
    /** The model stopped because it hit the token ceiling. */
    public const CUT_OFF = 'cut_off';

    /** The model replied with nothing at all. */
    public const EMPTY_REPLY = 'empty';

    /** The model replied, but not in a shape this page can read. */
    public const UNREADABLE = 'unreadable';

    /** The provider is rate limiting us, or is briefly unwell. */
    public const BUSY = 'busy';

    /**
     * The provider refused outright — a wrong model id, a dead key. Asking
     * again changes nothing, so the loop must not waste the shopkeeper's
     * time on it.
     */
    public const REFUSED = 'refused';

    public function __construct(
        public readonly string $kind,
        string $message,
    ) {
        parent::__construct($message);
    }

    /** Would a bigger token allowance plausibly fix this? */
    public function needsMoreRoom(): bool
    {
        return in_array($this->kind, [self::CUT_OFF, self::EMPTY_REPLY], true);
    }

    /** Is this worth waiting a moment and asking again? */
    public function needsAPause(): bool
    {
        return $this->kind === self::BUSY;
    }

    /** Could asking again plausibly produce a different answer? */
    public function worthRetrying(): bool
    {
        return $this->kind !== self::REFUSED;
    }
}
