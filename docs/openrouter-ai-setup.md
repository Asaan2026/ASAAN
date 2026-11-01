# Setting up OpenRouter for the dashboard's AI features

**No code change is needed.** The AI side of the dashboard was already built to
take any provider. OpenRouter speaks the same language as OpenAI, so it is a
matter of filling in three fields.

**The key does not go in this repository.** This repository is public. Type the
key into the dashboard, where it is stored in the database. (The Android signing
key is already in the public history — a separate problem, deliberately left
until after launch. Don't add a second one.)

---

## What the AI features are

Two, both in the dashboard, neither customer-facing:

| Feature | Where |
|---|---|
| Product Description Agent — writes a description, bullets and meta text for a product | Admin → Products → edit a product |
| Price Comparison Agent — suggests four pricing options | Same screen |

Both are off until a provider is configured.

---

## Steps

### 1. Add the provider

**Admin → Settings → AI → Providers → Add provider**

| Field | Value |
|---|---|
| Name | `OpenRouter` |
| Type | **Custom (OpenAI Compatible)** |
| Base URL | `https://openrouter.ai/api/v1` |
| API Key | your `sk-or-v1-…` key |

Then set **Default Provider** to `OpenRouter`.

### 2. Add a model

**Admin → Settings → AI → Models → Add model**

- Provider: `OpenRouter`
- Model: an id **ending in `:free`** (see the next section)

### 3. Point the two agents at it

**Admin → Settings → AI → Agents.** Set the provider and model on *Product
Description Agent* and *Price Comparison Agent*. Leave their prompts alone —
they are tuned to return the JSON the dashboard expects.

---

## Keeping it free

Two things matter, and only the second is a real guarantee.

**The model id must end in `:free`.** Anything else is billable. Checked against
OpenRouter on 2 November 2026 — 17 of their 452 models cost nothing. These were
among them:

```
openrouter/free                             (picks a free model for you)
nvidia/nemotron-3.5-lightning:free
nvidia/nemotron-3.5-super-vl:free
google/gemma-4-31b-it:free
google/gemma-4-26b-a4b-it:free
thinkingmachines/inkling:free
liquid/lfm-2.5-2.6b:free
```

That list changes often. The current one is at
<https://openrouter.ai/models?max_price=0>.

**The real guarantee is the account having no credits.** The key was checked on
2 November 2026 and the account is on the free tier with no credits and zero
usage. On a free-tier account a paid model does not quietly run up a bill — the
request **fails with an error**. So:

> **Never add credits to this OpenRouter account.** That, not the `:free`
> suffix, is what makes a charge impossible. If credits are ever added, set a
> per-key spending limit at <https://openrouter.ai/settings/keys> at the same
> time.

---

## What was actually tested, and how

On 2 November 2026, against the live OpenRouter API with this key:

| Check | Result |
|---|---|
| Key authenticates | Yes. `GET /api/v1/key` → HTTP 200, `is_free_tier: true`, `usage: 0`, no limit set |
| A free model answers | Yes. `openrouter/free` routed to `liquid/lfm-2.5-2.6b:free` and returned the exact text asked for |
| What it cost | `usage.cost: 0` |

Two things worth knowing from that test, because they will bite otherwise:

1. **Some free models are rate-limited.** `google/gemma-4-31b-it:free` and
   `liquid/lfm-2.5-2.6b:free` both returned **HTTP 429 — "temporarily
   rate-limited upstream"** when asked directly. This is normal for free
   capacity and says nothing about the key. `openrouter/free` worked, because it
   picks whichever free model is available. **Prefer `openrouter/free`** for
   that reason.
2. **Several free models are reasoning models, and the token limit must allow
   for it.** At `max_tokens: 30` two of them returned HTTP 200 with an *empty*
   answer: the budget went on internal reasoning and nothing was left for the
   reply. At 600 the same model answered correctly. The agents are set to 1024
   and 800 tokens, which is enough — but if an agent ever comes back blank with
   no error, this is why, and raising **Max tokens** on the agent is the fix.

The two agents themselves have **not** been run end to end, because that needs a
provider saved in the dashboard database, which is a thing to do in the dashboard
rather than in code.

---

## When the key is replaced

Change it in one place — Admin → Settings → AI → Providers → OpenRouter → API
Key. Nothing else refers to it.

**This key should be treated as public.** It was pasted into a chat, so anyone
with sight of that conversation has it. It is free-tier so it cannot cost
anything, but it can be used up by strangers. Worth replacing even before moving
to a paid key: <https://openrouter.ai/settings/keys>.
