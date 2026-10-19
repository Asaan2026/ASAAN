# Plan — Notifications (all platforms) and WhatsApp (everywhere)

Status: **in progress.** Phase 0 diagnosed and proven on 19 Oct 2026.
Investigated: 19 Oct 2026. All findings below were checked against the live server
and the working tree.

---

## Phase 0 result (19 Oct 2026) — push works, it was never triggered

**Confirmed with a controlled test against the live server.**

- The stored token `ctk_718ySFmFcd-cNV73cB:APA91bH…` (142 chars, user 3,
  android) is **valid**. Google accepted a test message and answered
  **HTTP 200** with `{"name":"projects/asaan-eb1c9/messages/0:1792374935951297%610451c8610451c8"}`.
  The `ctk_…` prefix is unusual but Google accepts the token as-is, so it was
  **not** deleted.
- Calling the real `CustomerNotificationService::notify()` for user 3 wrote
  `customer_notifications` row **id 1** and the push was accepted by Google.
- **Conclusion:** push was never broken. The only trigger is an order event, and
  the store has never had an order (`orders = 0`), so nothing ever fired. This is
  confirmed in writing as required by the definition of done.

Remaining for Phase 0: the manual check that the notification actually appears on
the physical phone (0.4 manual half), and 0.3 (silent-failure fix) is done.


---

## 1. What we found (the diagnosis)

### Push notifications are not broken. They have never fired.

Every part of the push path was tested on the live server:

| Check | Result |
|---|---|
| `FCM_PROJECT_ID` / `FCM_CREDENTIALS_PATH` env vars | Set correctly |
| Credentials file exists at that path | Yes |
| Google OAuth token actually obtained | **Yes** — `ya29.c.c0A…`, 1024 chars |
| Bound sender (real vs no-op) | `FcmPushSender`, not `NullPushSender` |
| `isConfigured()` | `true` |
| `OrderNotificationObserver` registered | Yes (`APIServiceProvider.php`) |
| Device token registered | 1 row — user 3, `android` |
| `customer_notifications` rows | **0** |
| `orders` rows | **0** |

The only trigger that exists is **an order being created or its status changing**.
The store has never had an order, so no notification row was ever written, so no
push was ever attempted. The mobile notification centre is empty because there is
genuinely nothing in it.

**Unverified — step 1 of Phase 0:** whether Google actually accepts a message sent
to the stored token. The stored token is `ctk_718ySFmFcd…`, 142 characters. That
is not the usual shape for an FCM registration token, and the string `ctk_` appears
**nowhere** in this codebase — so it arrived from the phone through the real
registration endpoint (`NotificationController::registerDevice`). It must be tested
with a controlled push.

### Silent-failure bug in the app

`mobile/lib/data/services/push_notification_service.dart:78` wraps the entire
Firebase start-up in `catch (_) {}`. If `Firebase.initializeApp()` throws on any
device (bad or mismatched `google-services.json`, network, permissions), the app
continues with push switched off and **nothing is logged, nothing is shown**. This
is why "it does not work" can be invisible per-device.

### Other confirmed facts

- The mobile app targets the **correct** domain and API version:
  `mobile/lib/core/config/api_config.dart:16` → `https://asaandotaf.store`,
  `:28` → `apiVersion = 'v1'`, notification endpoints `:53-61`.
- Registration chain is correct: `mobile/lib/main.dart:41` → `auth_service.dart:119`
  (sets `isLoggedIn`) → `:123` (`registerForCurrentUser`) →
  `push_notification_service.dart:96-111`; sign-out unregisters at `auth_service.dart:207`.
- The mobile app contains **no** hardcoded currency and **no** hardcoded category
  slugs. (An earlier report claiming an `INR` fallback in `api_config.dart` was wrong.)

---

## 2. What is actually missing

### A. The website has no notifications at all
- No bell, dropdown, unread badge or notifications page anywhere in
  `templates/storefront/general/cartxis-default/resources/views/`.
- No **web** route to read customer notifications. The existing routes are
  `auth:sanctum` only, for the app: `packages/Cartxis/API/Routes/api.php:216-226`.
- Only admin notifications are shared to the front end:
  `app/Http/Middleware/HandleInertiaRequests.php:154` → `adminNotifications`.
  There is no `customerNotifications` prop.
- No real-time layer: no `laravel-echo`, no `pusher-js` in `package.json`, no
  `config/broadcasting.php`, `.env.example:37` → `BROADCAST_CONNECTION=log`.
- No web push: `public/sw.js` has caching only, **no `push` event listener**, no VAPID keys.
- No polling on the storefront. Polling exists only in the admin:
  `resources/js/layouts/AdminLayout.vue:474-480` (every 30s).

### B. The dashboard has no notification settings
- FCM is environment-only: `config/services.php:51-57`
  (`FCM_PROJECT_ID`, `FCM_CREDENTIALS_PATH`, `FCM_ANDROID_CHANNEL`).
- Settings nav children are only eight items —
  `packages/Cartxis/Admin/src/Database/Seeders/AdminMenuSeeder.php:477-557` —
  and none of them is Notifications.
- No Firebase/FCM field exists on any admin page.
- The admin bell itself is not configurable.

### C. WhatsApp is uneven and cannot be switched off
- **Website** — component `WhatsAppButton.vue`, used at:
  - `components/ThemeHeader.vue:1011-1013` (desktop user dropdown)
  - `components/ThemeHeader.vue:1329-1332` (mobile drawer)
  - `components/ThemeFooter.vue:78`
  - `pages/Account/Dashboard.vue:541-543`
  - `pages/Account/Profile/Edit.vue:188`
  - Gating is **presence only**: if `store_whatsapp` has no digits it renders
    nothing (`WhatsAppButton.vue:41,79`). There is **no on/off switch**, no theme
    setting, and no placement control. Blanking the number hides it everywhere.
  - No floating button. The contact form (`pages/CMS/ContactForm.vue`) has no
    WhatsApp link.
- **Phone** — only `mobile/lib/features/product_details/screens/product_details_screen.dart`
  (builds `https://wa.me/…` at lines ~127-150). Not in contact, account, home or
  the drawer. Gated on `product.store?.whatsappNumber`, which is **not verified**
  to be present in the API payload.
- **Dashboard** — number field exists:
  `resources/js/pages/Admin/Settings/StoreConfiguration/Index.vue:659-678`
  (Contact & Address tab), validated `nullable|string|max:50` at
  `packages/Cartxis/Settings/src/Http/Controllers/Admin/StoreConfigurationController.php:108`,
  saved to group `store` at `:159`. No toggle, no placement, no message text.

### D. Latent bug found while investigating — settings cache desync
Two classes cache the **same** `settings` row under **different** keys:
- `packages/Cartxis/Core/src/Services/SettingService.php:14,26-28` → `settings:{key}`
- `packages/Cartxis/Settings/src/Models/Setting.php:29,57` → `setting.{key}`

Both TTL 3600s. A WhatsApp number changed through one path can be served stale by
the other for up to an hour. This will look like "my dashboard change did not apply".

### E. Notification triggers are too narrow
Only orders notify:
- customer: `packages/Cartxis/API/Observers/OrderNotificationObserver.php:19-31`
  (created + status changed), messages in `CustomerNotificationService:99-133`
- admin: `packages/Cartxis/Shop/src/Services/CheckoutService.php:199-250`,
  `packages/Cartxis/Sales/src/Services/OrderService.php:536-583` → `AdminNotificationService:15-56`

Missing: new product review (`ReviewController.php:44,106`), contact message
(`StorefrontController.php:40-73`), out-of-stock.

### F. `storeContact` shared prop is incomplete
`packages/Cartxis/Shop/src/Http/Middleware/ShareFrontendData.php:54-60` exposes
only `whatsapp, phone, email, playStoreUrl, appStoreUrl`. No `address`, no
`social_*`. The mobile API returns the same data under **different key names**
(snake_case) — `packages/Cartxis/API/Http/Controllers/V1/StorefrontController.php:82-88`.

---

## 3. The to-do list

### Phase 0 — Prove push reaches a phone (do first; nothing else matters if this fails)
- [ ] **0.1** Send one controlled test push to the stored token; record Google's
      exact response. Do not assume success.
- [ ] **0.2** If Google rejects it (404/410/INVALID_ARGUMENT), delete the stale
      `device_tokens` row and re-register from the phone.
- [ ] **0.3** Replace `catch (_) {}` in
      `mobile/lib/data/services/push_notification_service.dart:78` with logged
      failures (and a visible flag), so Firebase start-up problems stop being invisible.
- [ ] **0.4** Place a test order end-to-end; confirm a `customer_notifications`
      row is written and a push arrives. Confirm the notification centre shows it.

### Phase 1 — More reasons to notify
- [ ] **1.1** New product review → notify admins
      (`packages/Cartxis/API/Http/Controllers/V1/ReviewController.php:44`).
- [ ] **1.2** Contact form submission → notify admins
      (`packages/Cartxis/API/Http/Controllers/V1/StorefrontController.php:40-73`).
- [ ] **1.3** Leave order events as they are — already correct.

### Phase 2 — Notifications on the website
- [ ] **2.1** New **web** (session-auth, not `auth:sanctum`) routes: list,
      unread-count, mark-one-read, mark-all-read. Mirror
      `packages/Cartxis/API/Routes/api.php:216-222` but under `routes/web.php`
      or a web group. **Do not reuse the API routes** — they are token-only.
- [ ] **2.2** New web controller reusing `CustomerNotification` query logic from
      `packages/Cartxis/API/Http/Controllers/V1/NotificationController.php:21-85`.
- [ ] **2.3** Share `customerNotifications` (unread count + recent) to the
      storefront in `HandleInertiaRequests.php`, next to `adminNotifications` (line 154).
- [ ] **2.4** New bell component: icon + unread badge + dropdown list.
      Slot into `components/ThemeHeader.vue` right-hand icon row (~775-791, beside
      `CartIcon` at 775 and the wishlist badge at 778-791), and into the mobile
      drawer account block (~1269-1358).
- [ ] **2.5** Notifications page under `pages/Account/`, plus an entry in the
      shared `accountLinks` list (`ThemeHeader.vue:81-108`) so desktop and drawer
      cannot drift.
- [ ] **2.6** Refresh by **polling** every 30–60s, copying
      `resources/js/layouts/AdminLayout.vue:474-490` (fetch on mount, interval,
      cleared on unmount). Real-time (Echo/Reverb) is explicitly **out of scope**
      for this pass — it needs server infrastructure.

### Phase 3 — Dashboard controls for notifications
- [ ] **3.1** New settings page `resources/js/pages/Admin/Settings/Notifications/Index.vue`
      copying the `useForm` + `form.post` pattern from
      `StoreConfiguration/Index.vue:97-160`.
- [ ] **3.2** Routes in `packages/Cartxis/Settings/src/Routes/admin.php` under the
      `admin/settings` group (copy the Store Configuration pair at lines 29-30).
- [ ] **3.3** Controller with `index()`/`save()` using `SettingService::set()`
      (copy `StoreConfigurationController.php:82-173`).
- [ ] **3.4** Nav item in `AdminMenuSeeder.php:477-557` under the settings parent
      (copy the Store Configuration row at 488-497).
- [ ] **3.5** Fields: push enabled on/off, project id, credentials status
      (display the path + "file present" rather than storing the JSON in the
      database — a service-account key in the DB is a security risk), Android
      channel, plus per-event switches for customer and admin.
- [ ] **3.6** "Send test push" button that fires at the calling admin's/caller's
      device, so the owner can verify without placing an order.

### Phase 4 — WhatsApp on every platform
- [ ] **4.1** Website: add `whatsapp_enabled` toggle + placement choices
      (header, footer, product page, contact page, floating button) in the theme
      settings (`config/settings.php` Features section, lines 143-191) or the new
      settings page — decide one home and use it everywhere.
- [ ] **4.2** Website: change `WhatsAppButton.vue:41,79` from presence-only
      gating to `enabled && has digits`.
- [ ] **4.3** Website: add a WhatsApp option to `pages/CMS/ContactForm.vue`.
- [ ] **4.4** Website: optional floating button in `layouts/ThemeLayout.vue`
      (currently only "back to top" at 81-90).
- [ ] **4.5** Phone: add WhatsApp to contact, account and the drawer, reusing
      the `wa.me` builder already in `product_details_screen.dart:127-150`.
- [ ] **4.6** Phone: confirm the API actually returns the store number the button
      needs (check `/api/v1/storefront/contact` and the product payload's
      `store.whatsappNumber`). If missing, add it to the payload.
- [ ] **4.7** Dashboard: enable toggle, placement multi-select, pre-filled
      message text, in the Store Configuration page (or the new Notifications page).

### Phase 5 — Fix the settings cache desync
- [ ] **5.1** Make `SettingService` and `Settings\Models\Setting` use one
      identical cache key, then confirm a dashboard WhatsApp change is visible
      immediately on the storefront and the API.

### Phase 6 — Verify
- [ ] **6.1** Pest: web notification routes (auth, ownership — user A must not
      read user B's rows), settings save, WhatsApp visibility rules.
- [ ] **6.2** `php vendor\bin\pint` on changed PHP.
- [ ] **6.3** `php vendor\bin\pest` full suite (allow a long timeout — it exceeds 2 min).
- [ ] **6.4** `node C:\Users\Galez\AppData\Local\Temp\opencode\sfc-check.cjs <file>`
      for each changed Vue file (no local `npm run build` — the wayfinder plugin hangs).
- [ ] **6.5** Manual on a real phone: permission prompt, test push arrives, tap
      opens the right screen, notification centre lists it.
- [ ] **6.6** Manual on desktop and phone browser: bell shows and counts,
      WhatsApp appears when enabled and disappears when disabled.

---

## 4. Conventions and traps for whoever picks this up

- **Reply in plain English.** Say what broke in ordinary words, and state plainly
  whether something was verified and how.
- PowerShell quirks: `grep`/`Select-Object -First` inside ssh'd bash fails;
  `rg -r` is *replace*, not "recursive"; pipe scripts with
  `(@'…'@) -replace "`r","" | ssh … "bash -s"`; `curl` is an alias for
  Invoke-WebRequest (use `gh api` or `-UseBasicParsing`).
- DB access on live: write a `.php` on the host → `docker cp` into
  `asaan_online_store_app:/var/www/html/…` → `php artisan tinker <file>` → `rm`
  inside the container **and** on the host. Inline `--execute` in a piped script
  mangles `->`.
- Full suite: `php vendor\bin\pest` needs a timeout well above 120000 ms.
- Commit only when explicitly asked. Push to `client` (Asaan2026/ASAAN) is what
  deploys; `origin` alone does not.

## 5. Definition of done

1. A test push is proven to arrive on a real phone, and the reason it never fired
   is confirmed in writing here.
2. The website shows a working bell and a notifications page for the signed-in customer.
3. The dashboard has a Notifications section that can turn push on/off and send a test.
4. WhatsApp is present and controllable on the website, the phone app and from the
   dashboard, with an on/off switch on every one of them.
5. Tests, pint and the Vue check all pass, and the live site is verified by hand.
