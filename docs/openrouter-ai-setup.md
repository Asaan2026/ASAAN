# Adding the free OpenRouter AI key to the dashboard

**Nothing needs to be programmed.** The dashboard was already built to accept
any AI provider. OpenRouter speaks the same language as OpenAI, so it is
entirely a matter of filling in a few boxes.

Takes about five minutes.

---

## Before you start

**Do not put the key in the code.** Type it into the dashboard. The code
repository is public — anyone can read it.

---

## Step 1 — Open the AI settings

1. Sign in at **https://asaandotaf.store/admin**
2. In the left menu go to **Settings**
3. Open the **AI** page
4. Choose the **Providers** tab

---

## Step 2 — Add OpenRouter as a provider

Click **Add provider** and fill in exactly this:

| Box | What to type |
|---|---|
| **Name** | `OpenRouter` |
| **Type** | choose **Custom (OpenAI Compatible)** from the dropdown |
| **Base URL** | `https://openrouter.ai/api/v1` |
| **API Key** | your key, the long one starting `sk-or-v1-` |

Leave **Organization ID** and **Project ID** empty — OpenRouter does not use
them.

Click **Save**.

Then set **Default Provider** at the top of the page to **OpenRouter**.

---

## Step 3 — Add a model

Still on the AI page, go to the **Models** tab and click **Add model**.

| Box | What to type |
|---|---|
| **Provider** | `OpenRouter` |
| **Model** | `openrouter/free` |

Save.

**Why `openrouter/free` and not a specific model name.** It is not a model —
it is a switchboard. It sends your request to whichever free model is free at
that moment. When I tested your key, two named free models came back "busy, try
later" while `openrouter/free` answered first time. Picking one model by name
means picking one that is often busy.

---

## Step 4 — Point the two AI features at it

Go to the **Agents** tab. There are two, both built in:

- **Product Description Agent** — writes a product's description, bullet points
  and search text
- **Price Comparison Agent** — suggests four pricing options

Open each one and set:

- **Provider** → `OpenRouter`
- **Model** → `openrouter/free`

**Leave the prompt text alone.** Those prompts are written to make the AI reply
in the exact format the dashboard expects. Change the wording and the feature
stops working.

Save each one.

---

## Step 5 — Try it

1. Go to **Products**, open any product for editing
2. Find the **Generate with AI** button near the description
3. Click it

A description should appear within a few seconds.

---

## Keeping it free — the part that actually matters

There are two things people think protect them. Only one of them does.

**The weak one: the `:free` ending on a model name.** It means that model costs
nothing *today*. It is a label, not a lock. Type a different model name by
mistake and you are on a paid one.

**The real one: your account has no credits.**

I checked your key on 2 November 2026. The account is on the free tier, has
never been charged, and has no credits on it. On an account like that, asking
for a paid model does not quietly run up a bill — **the request simply fails
with an error message.** You cannot be charged for money you have not put in.

> ### The one rule
> **Never add credits to this OpenRouter account.**
>
> That is what makes a charge impossible. Not the model name.
>
> If you ever do add credits — for a paid model later — go to
> <https://openrouter.ai/settings/keys> at the same time and set a spending
> limit on the key, so a mistake cannot drain it.

---

## If something goes wrong

**"Rate limited" or "try again shortly"**
Normal on free models — too many people using them at that second. Wait a
minute and press the button again. If it happens constantly, make sure the
model is set to `openrouter/free` and not one specific model.

**It runs, says nothing failed, but the description comes back empty**
Some free models think to themselves before answering, and that thinking uses
up the reply allowance. Open the agent and raise **Max tokens** — try 2000.

**"AI provider not configured"**
Step 2 did not save, or **Default Provider** at the top of the page is not set
to OpenRouter.

**"AI provider request failed"**
Usually the key. Re-copy it — no spaces before or after.

---

## About the key you gave me

**Treat it as public and replace it.** You pasted it into a chat, so it exists
outside your control now. It cannot cost you anything, because the account has
no credits — but a stranger could use up your free allowance.

Make a new one at <https://openrouter.ai/settings/keys>, then change it in one
place: **Settings → AI → Providers → OpenRouter → API Key**. Nothing else in
the system refers to it.

---

## What was actually tested, and how

On 2 November 2026, against the live OpenRouter service with your key:

| Check | Result |
|---|---|
| Key works | Yes — the account responded, free tier, never used |
| A free model answers | Yes — `openrouter/free` chose `liquid/lfm-2.5-2.6b:free` and replied correctly |
| What it cost | Zero |

What I have **not** done: run the two dashboard features end to end. That needs
the provider saved in the dashboard, which is Step 2 above — a dashboard job,
not a code job. Step 5 is that test.
