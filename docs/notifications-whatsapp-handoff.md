# Handoff — Notifications (all platforms) and WhatsApp (everywhere)

> **For the next session.** Read this first, then
> [`notifications-whatsapp-plan.md`](notifications-whatsapp-plan.md) for the
> full phased to-do list. Investigation date: 19 Oct 2026.
> No work on this has started.

---

## The job

1. Make push notifications **actually deliver** to a phone.
2. Add notifications to the **website** (it has none at all).
3. Add **dashboard controls** for notifications (there are none).
4. Put **WhatsApp on every platform** — Android app, website — with proper
   on/off controls and settings for both WhatsApp and notifications.

---

## The headline finding

**Push notifications are not broken. They have never been triggered.**

Everything was tested live on 19 Oct 2026 and works:

- `FCM_PROJECT_ID=asaan-eb1c9`, credentials file present, **Google OAuth token
  obtained successfully** (`ya29.c.c0A…`, 1024 chars).
- Bound sender is `FcmPushSender`, `isConfigured() === true`.
- `OrderNotificationObserver` is registered.
- One device token registered: user 3 (`afzalakbari2016@gmail.com`), platform
  `android`, `last_seen 2026-10-18 05:27:46`.
- Tables `device_tokens` and `customer_notifications` both exist.

But: **`orders = 0`** and **`customer_notifications = 0`**.

The only trigger that exists is an order being created or its status changing.
No order has ever been placed, so no notification row was ever written, so no
push was ever attempted. The mobile notification centre is empty because there
is genuinely nothing in it.

### Open question that must be answered first

The stored token is `ctk_718ySFmFcd…`, **142 characters**. That is not the usual
shape of an FCM registration token, and the string `ctk_` appears **nowhere** in
this codebase — it arrived from the phone through the real endpoint
(`NotificationController::registerDevice`, `packages/Cartxis/API/...:105`).
**Send one controlled test push and record Google's actual response before doing
anything else.** Do not assume it works.

### Silent failure in the app (prime suspect for "it does not work")

`mobile/lib/data/services/push_notification_service.dart:78` wraps the whole
Firebase start-up in `catch (_) {}`. If `Firebase.initializeApp()` throws on a
device, push is silently off — no log, no message, no clue.

---

## What is missing (the actual scope)

| Area | State |
|---|---|
| Website notifications | **Nothing exists.** No bell, no page, no web route, no shared prop, no Echo/Pusher, no push handler in `public/sw.js`, no polling. |
| Dashboard notification settings | **Nothing exists.** FCM is env-only. No "Notifications" nav item. |
| WhatsApp on website | Exists in 5 places, but hidden **only** when the number is empty — no on/off switch, no placement control, no floating button, none on the contact form. |
| WhatsApp on phone app | **Product detail page only.** Not in contact, account, home or drawer. |
| WhatsApp in dashboard | Number field only. No toggle, no placement, no message text. |
| Notification triggers | **Orders only.** No reviews, no contact messages, no stock alerts. |

---

## Exact code locations (so you do not have to re-explore)

### Backend — notifications
- Routes (app only, `auth:sanctum`): `packages/Cartxis/API/Routes/api.php:216-226`
  — `GET notifications`, `unread-count`, `POST read-all`, `POST {id}/read`, `POST|DELETE devices`.
- Controller: `packages/Cartxis/API/Http/Controllers/V1/NotificationController.php`
  — `index:21-40`, `unreadCount:45-52`, `markRead:58-73`, `markAllRead:78-85`,
  `registerDevice:94-118` (body keys **`token`** + **`platform`**, not `fcm_token`),
  `unregisterDevice:123-138`.
- Models: `.../API/Models/CustomerNotification.php`, `.../API/Models/DeviceToken.php`.
- Migrations: `2026_10_16_100000_create_customer_notifications_table.php`,
  `2026_10_16_100001_create_device_tokens_table.php` (token unique, platform default `android`).
- Push: `packages/Cartxis/API/Services/Push/{PushSender,FcmPushSender,NullPushSender}.php`
  — `FcmPushSender` posts to `fcm.googleapis.com/v1/…:63`, signs a JWT with
  `openssl_sign:115`, caches the access token 50 min `:93`.
  `isConfigured():26-31` needs project id + `is_file(credentialsPath)`.
- Binding: `packages/Cartxis/API/Providers/APIServiceProvider.php:50-58`
  — **reads `config('services.fcm.credentials')`** (key is `credentials`, *not* `credentials_path`).
- Sending: `packages/Cartxis/API/Services/CustomerNotificationService.php`
  — `notify()`, `pushToDevices():76-91` (returns early if `!isConfigured()`),
  order messages `orderStatusMessage():99-133`.
- Trigger: `packages/Cartxis/API/Observers/OrderNotificationObserver.php:19-31`
  (registered at `APIServiceProvider.php:27`).
- Admin side (separate system, already working): `admin_notifications` table,
  `packages/Cartxis/Admin/src/Services/AdminNotificationService.php:15-56`,
  routes `packages/Cartxis/Admin/src/Routes/admin.php:41-45`.

### Config
- `config/services.php:51-57` → `FCM_PROJECT_ID`, `FCM_CREDENTIALS_PATH`,
  `FCM_ANDROID_CHANNEL` (currently **empty** — Firebase's default channel is used).
- Live server has all three set; credentials JSON at
  `/var/www/html/secrets/asaan-eb1c9-firebase-adminsdk-fbsvc-070abffefe.json`.
- **Not** in `.env.example` or `render.yaml`.

### Mobile app
- Config: `mobile/lib/core/config/api_config.dart`
  — `:16 productionBaseUrl = 'https://asaandotaf.store'`, `:28 apiVersion = 'v1'`,
  `:53-61` notification + device endpoints. **Correct — do not change.**
- Push: `mobile/lib/data/services/push_notification_service.dart`
  — `initialize():32-82` (swallows all errors at `:78`),
  `registerForCurrentUser():96-111` (early-returns unless `isLoggedIn`),
  `removeDevice():115-127`.
- Calls: `mobile/lib/main.dart:41`, `mobile/lib/data/services/auth_service.dart:119`
  (sets `isLoggedIn`), `:123` (register), `:207` (unregister on sign-out).
- API layer: `mobile/lib/data/services/notification_service.dart`.
- UI: `mobile/lib/presentation/screens/notifications/notifications_screen.dart`,
  `mobile/lib/core/utils/notification_navigator.dart`, bell in
  `mobile/lib/features/home/screens/home_screen.dart`.
- Firebase: `mobile/android/app/google-services.json` present; manifest declares
  `POST_NOTIFICATIONS`, `high_importance_channel`, `FirebaseMessagingService`.
- WhatsApp: **only** `mobile/lib/features/product_details/screens/product_details_screen.dart:127-150`
  (`https://wa.me/…` via `url_launcher`), gated on `product.store?.whatsappNumber`.

### Website (storefront theme = `templates/storefront/general/cartxis-default/resources/views/`)
- Header: `components/ThemeHeader.vue` — right icon row `601-791` (search 613-764,
  `CartIcon` 775, wishlist badge 778-791, user dropdown 814-1049);
  **mobile drawer** `1063-1363`, account block `1269-1358`;
  shared `accountLinks` list `81-108` (feeds both desktop and drawer).
- Footer: `components/ThemeFooter.vue:78`.
- WhatsApp component: `components/WhatsAppButton.vue` — gating at `:41` (has digits)
  and `:79` (`v-if`), variants `button|icon|link`, `block` flag.
- Shared props: `packages/Cartxis/Shop/src/Http/Middleware/ShareFrontendData.php`
  — `storeContact:54-60` (whatsapp, phone, email, playStoreUrl, appStoreUrl only),
  `categories:65-91`, `storefrontMenus:94`, `theme:97-123`.
- Floating elements: `layouts/ThemeLayout.vue:81-90` (back-to-top only).

### Dashboard (not a theme — it is `resources/js/pages/Admin/**` + `layouts/AdminLayout.vue`)
- Nav: `AdminLayout.vue:100-103` reads `page.props.menu.admin`, built by
  `HandleInertiaRequests.php:118-122` from
  `packages/Cartxis/Admin/src/Database/Seeders/AdminMenuSeeder.php`
  — settings children `477-557`, Store Configuration row `488-497`.
- Store Configuration page: `resources/js/pages/Admin/Settings/StoreConfiguration/Index.vue`
  — tabs `92`, `useForm` `97-127`, `save()` `129-160`, **WhatsApp field `659-678`**.
- Save pattern: `packages/Cartxis/Settings/src/Routes/admin.php:17-30` →
  `StoreConfigurationController.php:82-173` (`store_whatsapp` validated `:108`,
  saved `:159` to group `store`).
- Existing admin bell (copy this pattern for the storefront):
  `AdminLayout.vue:341-490` (axios + 30s interval), `871-1049` (badge + dropdown);
  seeded from `HandleInertiaRequests.php:154`.

---

## Traps — do not repeat these

1. **`config('services.fcm.credentials')`** is the correct key. There is no
   `credentials_path`. (I made this mistake while diagnosing and got a false
   "not configured".)
2. **Do not reuse the API notification routes for the website.** They are
   `auth:sanctum` (token) only; the website is session login. New web routes needed.
3. **`registerDevice` body keys are `token` and `platform`**, not `fcm_token`.
   There is no `/api/fcm-token` endpoint.
4. **Two settings caches use different keys** for the same row:
   `packages/Cartxis/Core/src/Services/SettingService.php:14,26` → `settings:{key}`
   vs `packages/Cartxis/Settings/src/Models/Setting.php:29,57` → `setting.{key}`.
   A dashboard change can appear stale for up to an hour. Fix in Phase 5.
5. **`storeContact` is incomplete** (no address, no socials) and the mobile API
   returns the same data with **snake_case** keys — the two shapes differ.
6. **Earlier reports in this project contained two errors** which are now
   corrected: the mobile app does **not** hardcode `asaan.online` (it is
   `asaandotaf.store`, correct), and it does **not** hardcode `INR`.
7. `WhatsAppButton` renders **nothing** when the number is empty — that is the
   only "off" switch that exists today, and it is global.

---

## Environment / how to run things

- Live: `ssh -i "$env:USERPROFILE\.ssh\asaan_vps" root@162.35.125.232`,
  repo `/opt/asaan`, containers `asaan_online_store_app` / `asaan_online_store_db`.
  Domain `https://asaandotaf.store` (matches `APP_URL`).
- PHP on the host is available:
  `C:\Users\Galez\AppData\Local\Microsoft\WinGet\Packages\PHP.PHP.8.3_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe`
  (8.3.32) → `$php vendor\bin\pint`, `$php vendor\bin\pest`.
- **Tests need a long timeout** — the full suite exceeds 120 s.
- **No local `npm run build`** — `vite.config.ts` imports the Wayfinder plugin
  which shells out to PHP and hangs. Build happens in CI/deploy.
- Vue check without a build:
  `node C:\Users\Galez\AppData\Local\Temp\opencode\sfc-check.cjs <file>` → `SFC_OK <file>`.
- Live DB edits: write `.php` on host → `docker cp` into the app container →
  `php artisan tinker <file>` → `rm` in container **and** on host.
  Inline `--execute` inside a piped script mangles `->`.
- Push to **`client`** (= `Asaan2026/ASAAN`) is what deploys; `origin` alone
  does not. CI: `gh run list --repo Asaan2026/ASAAN`.
- Commit only when explicitly asked.

---

## Definition of done

1. A test push is proven to arrive on a real phone, and the reason it never
   fired is written into the plan doc.
2. The website shows a working bell and a notifications page for the signed-in customer.
3. The dashboard has a Notifications section that can toggle push and send a test push.
4. WhatsApp is present and controllable on the website, the phone app and the
   dashboard — with a real on/off switch on every one of them.
5. Tests, pint and the Vue SFC check pass; the live site is verified by hand.
